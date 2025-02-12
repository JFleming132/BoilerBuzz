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

module.exports = router;


