// File: Routes/eventRoutes.js
const express = require('express');
const router = express.Router();
const Event = require('../Models/Event');
const User = require('../Models/User');
const { ObjectId } = require('mongodb');

// Get future RSVP events for a specific user
router.get('/user-events/:userId', async (req, res) => {
    try {
        const userId = req.params.userId;
        console.log(`🔍 Fetching future RSVP events for user: ${userId}`);
        
        if (!ObjectId.isValid(userId)) {
            return res.status(400).json({ message: 'Invalid user ID format' });
        }
        
        // Find the user to get their RSVP'd events
        const user = await User.findById(userId);
        
        if (!user || !user.rsvpEvents || user.rsvpEvents.length === 0) {
            console.log(`ℹ️ User ${userId} has no RSVP events`);
            return res.status(200).json([]);
        }
        
        // Convert all event IDs to ObjectId format
        const rsvpEventIds = user.rsvpEvents.map(id => 
            typeof id === 'string' ? new ObjectId(id) : id
        );
        
        const currentDate = new Date().getTime();
        console.log("📆 Current timestamp:", currentDate);
        
        // Find all future events that the user has RSVP'd to
        const events = await Event.find({
            _id: { $in: rsvpEventIds },
            date: { $gte: currentDate }
        });
        
        console.log(`✅ Found ${events.length} future RSVP event(s) for user ${userId}`);
        
        // Print event IDs to console as requested
        events.forEach(event => {
            console.log(`Future RSVP Event ID: ${event._id}`);
        });
        
        const sanitizedEvents = events.map(event => ({
            _id: event._id.toString(),
            title: event.title,
            description: event.description || "",
            location: event.location,
            date: Number(event.date),
            authorUsername: event.authorUsername || ""
        }));
        
        res.status(200).json(sanitizedEvents);
    } catch (err) {
        console.error("❌ Error fetching user's RSVP events:", err.message);
        console.error("🔍 Stack trace:", err.stack);
        res.status(500).json({ message: 'Error fetching RSVP events', error: err.message });
    }
});

module.exports = router;
