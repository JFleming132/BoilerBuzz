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
        console.log(`🔍 Fetching user data for: ${userId}`);
        
        // Validate ObjectId
        if (!ObjectId.isValid(userId)) {
            return res.status(400).json({ 
                success: false,
                message: 'Invalid user ID format' 
            });
        }
        
        // Find user and populate their data
        const user = await User.findById(userId)
            .select('rsvpEvents friends')
            .lean();
        
        if (!user) {
            return res.status(404).json({ 
                success: false,
                message: 'User not found' 
            });
        }
        
        // 1. Get RSVP Events
        const rsvpEventIds = user.rsvpEvents.map(id => 
            typeof id === 'string' ? new ObjectId(id) : id
        );
        
        const currentDate = new Date().getTime();
        const events = await Event.find({
            _id: { $in: rsvpEventIds },
            date: { $gte: currentDate }
        })
        .select('_id title description location date author authorUsername')
        .lean();
        
        // 2. Get Friends List
        const friends = user.friends || [];
        
        // 3. Format Response
        const response = {
            success: true,
            data: {
                events: events.map(event => ({
                    _id: event._id.toString(),
                    title: event.title,
                    description: event.description || "",
                    location: event.location,
                    date: Number(event.date),
                    authorUsername: event.authorUsername || "",
                    authorUserId: event.author.toString()
                })),
                friends: friends.map(friendId => friendId.toString())
            }
        };
        
        res.status(200).json(response);
        
    } catch (err) {
        console.error("❌ Error in /user-events:", err.message);
        console.error("🔍 Stack trace:", err.stack);
        
        res.status(500).json({ 
            success: false,
            message: 'Server error',
            error: process.env.NODE_ENV === 'development' ? err.message : undefined
        });
    }
});

module.exports = router;
