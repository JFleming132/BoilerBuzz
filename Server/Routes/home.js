const express = require('express');
const router = express.Router();
const Event = require('../Models/Event'); // Ensure correct path to Event model
const User = require('../Models/User');   // Ensure correct path to User model

router.post('/events', async (req, res) => {
    try {
        const { title, description, location, capacity, is21Plus, date, imageUrl } = req.body;

        if (!title || !location || !capacity || !date) {
            return res.status(400).json({ message: 'Missing required fields' });
        }

        const formattedDate = new Date(date).getTime(); // ✅ Convert to timestamp (ms)

        if (isNaN(formattedDate)) {
            return res.status(400).json({ message: 'Invalid date format' });
        }

        const newEvent = new Event({
            title,
            description,
            location,
            capacity,
            is21Plus,
            date: formattedDate,  // ✅ Store in milliseconds
            imageUrl
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
        const currentDate = new Date().getTime(); // ✅ Compare using timestamps
        const events = await Event.find({ date: { $gte: currentDate } });

        const sanitizedEvents = events.map(event => ({
            ...event.toObject(),
            date: event.date, // ✅ Return Unix timestamp directly
            imageUrl: event.imageUrl || "" 
        }));

        console.log("📥 Fetching events from DB:", sanitizedEvents);
        res.json(sanitizedEvents);
    } catch (err) {
        console.error("❌ Error fetching events:", err);
        res.status(500).json({ message: 'Error fetching events', error: err });
    }
});

module.exports = router;

