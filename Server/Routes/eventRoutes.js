const express = require('express');
const router = express.Router();
const Event = require('../Models/Event');
const User = require('../Models/User');
const NameList = require('../Models/NameList');
const { ObjectId } = require('mongodb');

// ========================
//  GET ALL EVENTS
// ========================
router.get('/all', async (req, res) => {
    try {
        const currentDate = new Date().getTime();
        
        // 1. Get ALL events (future-only by default)
        const events = await Event.find({
            date: { $gte: currentDate } // Remove this line for past+future events
        })
        .select('_id title description location date author authorUsername')
        .lean();

        // 2. Get unique organizer usernames
        const usernames = [...new Set(events.map(e => e.authorUsername))];
        
        // 3. Get names from NameList
        const nameListEntries = await NameList.find({ 
            username: { $in: usernames } 
        }).lean();

        // 4. Create name lookup map
        const nameMap = nameListEntries.reduce((acc, entry) => {
            acc[entry.username] = `${entry.firstName} ${entry.lastName}`;
            return acc;
        }, {});

        // 5. Format response
        const response = {
            success: true,
            data: events.map(event => ({
                _id: event._id.toString(),
                title: event.title,
                description: event.description || "",
                location: event.location,
                date: Number(event.date),
                authorUsername: event.authorUsername || "",
                authorUserId: event.author.toString(),
                organizerName: nameMap[event.authorUsername] || event.authorUsername,
                imageUrl: event.imageUrl || "" // Added image URL
            }))
        };

        res.status(200).json(response);

    } catch (err) {
        console.error("❌ GET /all Error:", err.message);
        res.status(500).json({ 
            success: false,
            message: 'Failed to fetch events',
            error: process.env.NODE_ENV === 'development' ? err.message : undefined
        });
    }
});

// ========================
//  GET USER-SPECIFIC EVENTS
// ========================
router.get('/user-events/:userId', async (req, res) => {
    try {
        const userId = req.params.userId;
        
        // 1. Validate ObjectId
        if (!ObjectId.isValid(userId)) {
            return res.status(400).json({ 
                success: false,
                message: 'Invalid user ID format' 
            });
        }
        
        // 2. Find user and their RSVP events
        const user = await User.findById(userId)
            .select('rsvpEvents friends')
            .lean();
        
        if (!user) {
            return res.status(404).json({ 
                success: false,
                message: 'User not found' 
            });
        }
        
        // 3. Convert RSVP event IDs to ObjectIds
        const rsvpEventIds = user.rsvpEvents.map(id => 
            typeof id === 'string' ? new ObjectId(id) : id
        );
        
        // 4. Get future RSVP events
        const currentDate = new Date().getTime();
        const events = await Event.find({
            _id: { $in: rsvpEventIds },
            date: { $gte: currentDate }
        })
        .select('_id title description location date author authorUsername imageUrl')
        .lean();
        
        // 5. Get organizer names
        const usernames = [...new Set(events.map(e => e.authorUsername))];
        const nameListEntries = await NameList.find({ 
            username: { $in: usernames } 
        }).lean();
        
        const nameMap = nameListEntries.reduce((acc, entry) => {
            acc[entry.username] = `${entry.firstName} ${entry.lastName}`;
            return acc;
        }, {});

        // 6. Format final response
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
                    authorUserId: event.author.toString(),
                    organizerName: nameMap[event.authorUsername] || event.authorUsername,
                    imageUrl: event.imageUrl || ""
                })),
                friends: (user.friends || []).map(friendId => friendId.toString())
            }
        };
        
        res.status(200).json(response);
        
    } catch (err) {
        console.error("❌ GET /user-events Error:", err.message);
        res.status(500).json({ 
            success: false,
            message: 'Server error',
            error: process.env.NODE_ENV === 'development' ? err.message : undefined
        });
    }
});

module.exports = router;

