//
//  drinks.js
//  BoilerBuzz
//
//  Created by Matt Zlatniski on 2/16/25.
//
const express = require('express');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const User = require('../Models/User');
const nodemailer = require('nodemailer');
const crypto = require('crypto');
const mongoose = require('mongoose');

const router = express.Router();

router.post('/toggleTriedDrink', async (req, res) => {
    const { userId, objectID } = req.body;

    if (!mongoose.Types.ObjectId.isValid(userId)) {
        return res.status(400).json({ error: 'Invalid user Id' });
    }

    try {
        const user = await User.findById(userId);

        if (!user) {
            return res.status(404).json({ error: 'User not found' });
        }

        // Check if the objectID exists in the user's triedDrinks array
        if (user.triedDrinks.includes(objectID)) {
            // Remove the objectID if it's already in the triedDrinks array
            user.triedDrinks = user.triedDrinks.filter(id => id !== objectID);
        } else {
            // Add the objectID to the triedDrinks array if it's not already there
            user.triedDrinks.push(objectID);
        }

        // Save the updated user document
        await user.save();
        return res.json({ success: true });

    } catch (error) {
        console.error('Error toggling tried drink:', error);
        return res.status(500).json({ error: 'Internal server error' });
    }
});

// Fetch tried drinks for a user
router.get('/triedDrinks/:userId', async (req, res) => {
    const { userId } = req.params;

    if (!mongoose.Types.ObjectId.isValid(userId)) {
        return res.status(400).json({ error: 'Invalid user Id' });
    }

    try {
        const user = await User.findById(userId);

        if (!user) {
            return res.status(404).json({ error: 'User not found' });
        }

        // Return the triedDrinks array
        return res.json({ triedDrinks: user.triedDrinks });

    } catch (error) {
        console.error('Error fetching tried drinks:', error);
        return res.status(500).json({ error: 'Internal server error' });
    }
});


module.exports = router;
