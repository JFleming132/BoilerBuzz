const express = require('express');
const router = express.Router();
const Event = require('../Models/Event'); // Ensure correct path to Event model
const User = require('../Models/User');   // Ensure correct path to User model

router.post('/events', async (req, res) => {
    try {
        const { title, author, rsvpCount, promoted, description, location, capacity, is21Plus, date, imageUrl, authorUsername } = req.body;

        if (!title || !location || !capacity || !date) {
            return res.status(400).json({ message: 'Missing required fields' });
        }

        const formattedDate = new Date(date).getTime();

        if (isNaN(formattedDate)) {
            return res.status(400).json({ message: 'Invalid date format' });
        }

        const newEvent = new Event({
            //Done: Add Author, RSVPcount, and Promoted status
            title,
            author,
            rsvpCount,
            promoted,
            description,
            location,
            capacity,
            is21Plus,
            date: formattedDate,
            imageUrl: imageUrl || "", // ✅ Store Base64 or empty string
            authorUsername
        });

        await newEvent.save();

        console.log("✅ Event created successfully:", newEvent);
        res.status(201).json(newEvent);
    } catch (err) {
        console.error("❌ Error creating event:", err);
        res.status(500).json({ message: 'Error saving event', error: err });
    }
});

router.get('/events', async (req, res) => {
    try {
        const currentDate = new Date().getTime();
        const events = await Event.find({ date: { $gte: currentDate } }); //TODO: Add functionality for block lists

        const sanitizedEvents = events.map(event => ({
            _id: event._id.toString(), // Convert ObjectId to plain string
            title: event.title,
            description: event.description || "",
            location: event.location,
            capacity: Number(event.capacity),
            is21Plus: Boolean(event.is21Plus),
            date: Number(event.date), // Already milliseconds
            imageUrl: event.imageUrl || ""
        }));

        console.log("📥 Fetching events from DB:", sanitizedEvents);
        res.json(sanitizedEvents);
    } catch (err) {
        console.error("❌ Error fetching events:", err);
        res.status(500).json({ message: 'Error fetching events', error: err });
    }
});

//These next two methods are copied/modified versions of addfriend/removefriend
router.post('/rsvp', async (req, res) => {
    const { userId, eventId } = req.body;
    
    // Validate that the user IDs are valid ObjectIds if stored that way.
    if (!mongoose.Types.ObjectId.isValid(userId) || !mongoose.Types.ObjectId.isValid(eventId)) {
        return res.status(400).json({ error: 'Invalid user Id or event Id)' });
    }
    
    try {
        // Find the current user by their ID.
        const user = await User.findById(userId);
        if (!user) {
            return res.status(404).json({ error: "User not found" });
        }
        
        // Ensure the friends field exists.
        if (!user.rsvpEvents) {
            user.rsvpEvents = [];
        }
        
        // Add friendId to the user's friends list if it's not already there.
        if (!user.rsvpEvents.includes(eventId)) {
            user.rsvpEvents.push(eventId);
        }
        
        // Save the updated user document.
        await user.save({ validateBeforeSave: false });
        
        res.status(200).json({ success: true, rsvpEvents: user.rsvpEvents });
    } catch (error) {
        console.error('Error adding friend:', error);
        res.status(500).json({ error: 'Internal server error' });
    }
});

router.post('/unrsvp', async (req, res) => {
    const { userId, eventId } = req.body;
    
    // Validate that the user IDs are valid ObjectIds if necessary.
    if (!mongoose.Types.ObjectId.isValid(userId) || !mongoose.Types.ObjectId.isValid(eventId)) {
        return res.status(400).json({ error: 'Invalid user Id or event Id' });
    }
    
    try {
        // Find the current user by their ID.
        const user = await User.findById(userId);
        if (!user) {
            return res.status(404).json({ error: "User not found" });
        }
        
        // Ensure the friends field exists.
        if (!user.rsvpEvents) {
            user.rsvpEvents = [];
        }
        
        // Remove friendId from the user's friends array.
        user.rsvpEvents = user.rsvpEvents.filter(id => id.toString() !== eventId);
        
        // Save the updated user document.
        await user.save({ validateBeforeSave: false });
        
        res.status(200).json({ success: true, friends: user.friends });
    } catch (error) {
        console.error('Error removing rsvp event:', error);
        res.status(500).json({ error: 'Internal server error' });
    }
});

module.exports = router;

