const mongoose = require('mongoose');
const express = require('express');
const router = express.Router();
const CampusStatus = require('../Models/CampusStatus');

// Geofence calculation
function isWithinCampus(location) {
  const campusCenter = { lat: 40.4237, lng: -86.9232 };
  const radius = 16000; // meters which is a 10 mi radius

  const R = 6371000; // Earth's radius
  const dLat = (location.latitude - campusCenter.lat) * Math.PI/180;
  const dLon = (location.longitude - campusCenter.lng) * Math.PI/180;
  
  const a = Math.sin(dLat/2) * Math.sin(dLat/2) +
            Math.cos(campusCenter.lat * Math.PI/180) * 
            Math.cos(location.latitude * Math.PI/180) *
            Math.sin(dLon/2) * Math.sin(dLon/2);
            
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a));
  const distance = R * c;
  
  return distance <= radius;
}

router.get('/:userId/campus-status', async (req, res) => {
  try {
    const userId = req.params.userId;

    // Validate ObjectId
    if (!mongoose.Types.ObjectId.isValid(userId)) {
      return res.status(400).json({ error: 'Invalid userId format' });
    }

    const objectId = new mongoose.Types.ObjectId(userId);

    // Get most recent location
    const recentLocation = await mongoose.connection.db.collection('user_locations')
      .findOne(
        { userId: objectId },
        { 
          sort: { lastUpdate: -1 }, 
          projection: { _id: 0, latitude: 1, longitude: 1, lastUpdate: 1 } 
        }
      );

    // Check if location is recent (within 1 hours)
    const locationExpiryMinutes = 60;
    const isLocationRecent = recentLocation && 
      (Date.now() - new Date(recentLocation.lastUpdate).getTime()) < 
      locationExpiryMinutes * 60 * 1000;

    // Calculate campus status
    const isOnCampus = isLocationRecent ? 
      isWithinCampus(recentLocation) : false;

    // Update status record
    await CampusStatus.updateOne(
      { userId: objectId },
      { 
        $set: { 
          isOnCampus,
          lastChecked: new Date() 
        }
      },
      { upsert: true }
    );

    res.json({
      isOnCampus,
      lastChecked: new Date(),
      lastLocation: recentLocation || null,
      isLocationRecent // For debugging
    });

  } catch (error) {
    console.error('Campus status error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

module.exports = router;
