// routes/location.js
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
            { userId: userId },
            { 
                userId: userId,
                latitude: latitude,
                longitude: longitude,
                lastUpdate: new Date()
            },
            { upsert: true, new: true }
        );

        res.status(200).json({ success: true, message: "Location updated successfully", location: updatedLocation });
    } catch (error) {
        console.error("Error updating location:", error);
        res.status(500).json({ error: "Internal server error" });
    }
});

module.exports = router;
