const express = require('express');
const UserLocation = require('../Models/UserLocation');
const router = express.Router();
const mongoose = require('mongoose');

router.post('/updateLocation', async (req, res) => {
    const { userId, latitude, longitude } = req.body;

    if (!mongoose.Types.ObjectId.isValid(userId)) {
        return res.status(400).json({ error: 'Invalid user Id' });
    }

    try {
        const updatedLocation = await UserLocation.findOneAndUpdate(
            { userId: userId },  // Search for existing location by userId
            { 
                userId: userId,
                latitude: latitude,
                longitude: longitude,
                lastUpdate: new Date() 
            },
            { upsert: true, new: true }  // Create new if not exists, and return the updated document
        );

        // Log to check if the location was updated or created
        if (updatedLocation) {
            console.log("✅ Location updated or created:", updatedLocation);
        } else {
            console.log("❌ No location was created or updated.");
        }

        res.status(200).json({
            success: true,
            message: "Location updated successfully",
            location: updatedLocation
        });
    } catch (error) {
        console.error("❌ Error updating location:", error);
        res.status(500).json({ error: "Internal server error" });
    }
});

module.exports = router; // Ensure it's exported correctly

