//
//  auth.js
//  BoilerBuzz
//
//  Created by Matt Zlatniski on 2/12/25.
//
//
const express = require('express');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const mongoose = require('mongoose');


const router = express.Router();

// Sign-up route
router.post('/signup', async (req, res) => {
    const { username, password } = req.body;
    console.log(`got signup request with username: ${username} and password: ${password}`);
    
    res.status(201).json({ message: 'Got user signup request!' });
});

// Login route
router.post('/login', async (req, res) => {
    const { username, password } = req.body;
    console.log(`got login request with username: ${username} and password: ${password}`);
    
    res.status(201).json({ message: 'Got user login request!' });
});

// Drinks route
router.get('/drinks', async (req, res) => {
    try {
        // Explicitly switch to the `Boiler_Buzz` database
        const db = mongoose.connection.client.db('Boiler_Buzz');
        
        // Access the `drinks` collection in the `Boiler_Buzz` database
        const drinks = await db.collection('drinks').find().toArray();

        if (drinks.length === 0) {
            return res.status(404).json({ error: "Drinks could not be found" });
        }

        res.json(drinks); // Return the list of drinks
    } catch (error) {
        console.error("Error fetching drinks:", error.message);
        res.status(500).json({ error: "Failed to fetch drinks. Please try again later." });
    }
});


module.exports = router;


