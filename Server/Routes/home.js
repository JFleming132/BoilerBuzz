const express = require('express');
const router = express.Router();
const Event = require('../Models/Event'); // Ensure correct path to Event model
const User = require('../Models/User');   // Ensure correct path to User model
const HarrysCount = require('../Models/harrys'); // Ensure correct import
const mongoose = require('mongoose');

router.get('/harrys/line', async (req, res) => {
    try {
        console.log("Fetching data for Harry's...");

        // Correct model usage
        const harrysData = await HarrysCount.findOne({ _id: "harrys" });

        if (!harrysData) {
            console.log("❌ No data found in DB");
            return res.status(404).json({ message: "No data found" });
        }

        console.log("✅ Data found:", harrysData);
        res.json({
            people_in_bar: harrysData.people_in_bar,
            people_in_line: harrysData.people_in_line,
            last_updated: harrysData.last_updated
        });
    } catch (err) {
        console.error("❌ Error fetching Harry's data:", err);
        res.status(500).json({ message: "Error fetching data", error: err });
    }
});

router.post('/events', async (req, res) => {
    try {
        const { title, description, location, capacity, is21Plus, date, imageUrl } = req.body;

        if (!title || !location || !capacity || !date) {
            return res.status(400).json({ message: 'Missing required fields' });
        }

        const formattedDate = new Date(date).getTime();

        if (isNaN(formattedDate)) {
            return res.status(400).json({ message: 'Invalid date format' });
        }

        const newEvent = new Event({
            title,
            description,
            location,
            capacity,
            is21Plus,
            date: formattedDate,
            imageUrl: imageUrl || "" // ✅ Store Base64 or empty string
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
        const events = await Event.find({ date: { $gte: currentDate } });

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

// New endpoint to get events by creator ID
router.get('/events/byUser/:userId', async (req, res) => {
    try {
        const { userId } = req.params;

        if (!mongoose.Types.ObjectId.isValid(userId)) {
            userId = mongoose.Types.ObjectId(userId);
        }

        // Find events where the creator field matches the provided userId
        const events = await Event.find({ author: userId });

        console.log("🔍 Found events:", events);

        if (!events) {
            return res.status(404).json({ message: 'No events found for this user' });
        }

        // Sanitize the events similar to the general events endpoint
        const sanitizedEvents = events.map(event => ({
            _id: event._id.toString(),
            title: event.title,
            description: event.description || "",
            location: event.location,
            capacity: Number(event.capacity),
            is21Plus: Boolean(event.is21Plus),
            date: Number(event.date),
            imageUrl: event.imageUrl || "",
            author: event.author ? event.author.toString() : null
        }));

        console.log(`📥 Fetching events for user ${userId}:`, sanitizedEvents.length);
        res.json(sanitizedEvents);

    } catch (err) {
        console.error(`❌ Error fetching events for user ${req.params.userId}:`, err);
        res.status(500).json({ message: 'Error fetching user events', error: err });
    }
});

router.delete('/delEvents/:eventId', async (req, res) => {
    try {
        const { eventId } = req.params;
        const deletedEvent = await Event.findByIdAndDelete(eventId);
        if (!deletedEvent) {
            return res.status(404).json({ message: "Event not found" });
        }
        res.status(200).json({ message: "Event deleted successfully" });
    } catch (err) {
        console.error("Error deleting event:", err);
        res.status(500).json({ message: 'Error deleting event', error: err });
    }
});


module.exports = router;

