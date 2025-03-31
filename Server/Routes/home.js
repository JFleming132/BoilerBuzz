const mongoose = require('mongoose');
const express = require('express');
const router = express.Router();
const Event = require('../Models/Event'); // Ensure correct path
const User = require('../Models/User');   // Ensure correct path

// Create a new event (unchanged)
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
            title,
            author,
            rsvpCount,  // Should be 0 on creation
            promoted,
            description,
            location,
            capacity,
            is21Plus,
            date: formattedDate,
            imageUrl: imageUrl || "",
            authorUsername
        });

        await newEvent.save();
	
	// Add event ID to user's pastEvents
        await User.findByIdAndUpdate(author, {
            $push: { pastEvents: newEvent._id }
        });
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
        console.log("📆 Current timestamp:", currentDate);
        console.log("🧠 Attempting to fetch upcoming events from DB...");

        const events = await Event.find({ date: { $gte: currentDate } });
        console.log(`✅ Found ${events.length} event(s)`);

        const sanitizedEvents = events.map(event => ({
            _id: event._id.toString(),
            title: event.title,
            author: event.author?.toString() || "", // Ensure author is a string
            rsvpCount: event.rsvpCount || 0,
            description: event.description || "",
            location: event.location,
            capacity: Number(event.capacity),
            is21Plus: Boolean(event.is21Plus),
            promoted: Boolean(event.promoted),
            date: Number(event.date),
            imageUrl: event.imageUrl || "",
            authorUsername: event.authorUsername || ""
        }));

        res.status(200).json(sanitizedEvents); // Return as a pure array

    } catch (err) {
        console.error("❌ Error fetching events:", err.message);
        console.error("🔍 Stack trace:", err.stack);
        res.status(500).json({ message: 'Error fetching events', error: err.message });
    }
});

//rsvp endpoint
router.post('/rsvp', async (req, res) => {
    const { userId, eventId } = req.body;

    console.log("📥 RSVP request received");
    console.log("👉 userId:", userId);
    console.log("👉 eventId:", eventId);

    if (!mongoose.Types.ObjectId.isValid(userId) || !mongoose.Types.ObjectId.isValid(eventId)) {
        return res.status(400).json({ error: 'Invalid user Id or event Id' });
    }

    try {
        const user = await User.findById(userId);
        if (!user) {
            console.log("❌ User not found");
            return res.status(404).json({ error: "User not found" });
        }

        const event = await Event.findById(eventId);
        if (!event) {
            console.log("❌ Event not found");
            return res.status(404).json({ error: "Event not found" });
        }

        // Initialize if undefined
        user.rsvpEvents = user.rsvpEvents || [];

        const alreadyRSVPed = user.rsvpEvents.includes(eventId);
        console.log("✅ RSVP already exists?", alreadyRSVPed);

        if (!alreadyRSVPed) {
            user.rsvpEvents.push(eventId);
            event.rsvpCount = (event.rsvpCount || 0) + 1;

            await user.save({ validateBeforeSave: false });
            await event.save({ validateBeforeSave: false });

            console.log("✅ RSVP added successfully");
        }
        

        res.status(200).json({
            success: true,
            rsvpEvents: user.rsvpEvents,
            rsvpCount: event.rsvpCount
        });

    } catch (error) {
        console.error("❌ RSVP error:", error);
        res.status(500).json({ error: "Internal server error" });
    }
});

// UnRSVP endpoint
router.post('/unrsvp', async (req, res) => {
    const { userId, eventId } = req.body;
    
    if (!mongoose.Types.ObjectId.isValid(userId) || !mongoose.Types.ObjectId.isValid(eventId)) {
        return res.status(400).json({ error: 'Invalid user Id or event Id' });
    }
    
    try {
        // Update user: remove eventId.
        const user = await User.findById(userId);
        if (!user) return res.status(404).json({ error: "User not found" });
        
        if (!user.rsvpEvents) user.rsvpEvents = [];
        user.rsvpEvents = user.rsvpEvents.filter(id => id.toString() !== eventId);
        await user.save({ validateBeforeSave: false });
        
        // Update event: decrement RSVP count.
        const event = await Event.findById(eventId);
        if (event) {
            event.rsvpCount = Math.max(0, event.rsvpCount - 1);
            await event.save();
            console.log("UnRSVP updated. New event count:", event.rsvpCount);
        }
        
        res.status(200).json({ success: true, rsvpEvents: user.rsvpEvents });
    } catch (error) {
        console.error('Error removing RSVP event:', error);
        res.status(500).json({ error: 'Internal server error' });
    }
});

// Update event and notify RSVP'd users
router.post('/update-event', async (req, res) => {
    try {
        const { eventId, title, description, location, date, capacity } = req.body;

        if (!mongoose.Types.ObjectId.isValid(eventId)) {
            return res.status(400).json({ error: 'Invalid event ID' });
        }

        const updatedEvent = await Event.findByIdAndUpdate(
            eventId,
            {
                title,
                description,
                location,
                date: new Date(date).getTime(),
                capacity
            },
            { new: true }
        );

        if (!updatedEvent) {
            return res.status(404).json({ error: 'Event not found' });
        }

        // Get users who RSVP'd
        const rsvpUsers = await User.find({ rsvpEvents: eventId });

        const emails = rsvpUsers.map(user => user.email).filter(Boolean);

        // You would use a real email service here
        console.log("📧 Sending emails to:", emails);

        // Simulated email response
        res.status(200).json({
            success: true,
            updatedEvent,
            notifiedEmails: emails
        });

    } catch (err) {
        console.error("❌ Error updating event:", err);
        res.status(500).json({ error: 'Server error updating event' });
    }
});


// PUT /api/home/events/:id — Update event info
router.put('/events/:id', async (req, res) => {
    const eventId = req.params.id;

    if (!mongoose.Types.ObjectId.isValid(eventId)) {
        return res.status(400).json({ error: 'Invalid event ID' });
    }

    try {
        const { title, description, location, date, capacity, is21Plus, promoted, imageUrl } = req.body;

        const updatedEvent = await Event.findByIdAndUpdate(
            eventId,
            {
                title,
                description,
                location,
                date: new Date(date).getTime(),
                capacity,
                is21Plus,
                promoted,
                imageUrl
            },
            { new: true }
        );

        if (!updatedEvent) {
            return res.status(404).json({ error: 'Event not found' });
        }

        console.log("✅ Event updated:", updatedEvent);
        res.status(200).json(updatedEvent);

    } catch (err) {
        console.error("❌ Error updating event:", err);
        res.status(500).json({ error: 'Server error updating event' });
    }
});

module.exports = router;

