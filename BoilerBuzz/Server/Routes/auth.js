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
const User = require('../Models/User');
const nodemailer = require('nodemailer');
const crypto = require('crypto');

const router = express.Router();

// Sign-up route
router.post('/signup', async (req, res) => {
    const { email, username, password } = req.body;
    console.log(`got signup request with username: ${username} and password: ${password}`);
    
    if (!password || password.trim() === '') {
       return res.status(400).json({ message: 'Password cannot be empty' });
   }
    
    const userExists = await User.findOne({ username });
    if (userExists) {
        return res.status(400).json({ message: 'Username already exists' });
    }
    
    const emailExists = await User.findOne({ email });
    if (emailExists) {
        return res.status(400).json({ message: 'Email already exists' });
    }
    
    // Check if email follows the required format
    const emailRegex = /^[a-zA-Z0-9._%+-]+@purdue\.edu$/;
    if (!emailRegex.test(email)) {
        return res.status(400).json({ message: 'Email must be a purdue.edu email' });
    }
    
    try {
        const hashedPassword = await bcrypt.hash(password, 10);
        
        const verificationToken = crypto.randomBytes(32).toString('hex');

        const newUser = new User({
            email,
            username,
            password: hashedPassword,
            verificationToken
        });
        
        await newUser.save();
        
        // Send verification email via gmail
        const transporter = nodemailer.createTransport({
            service: 'gmail',
            auth: {
                user: 'theboilerbuzz@gmail.com',
                pass: 'zgfpwmppahiauhyc'
            }
        });
        
        const mailOptions = {
            from: 'theboilerbuzz@gmail.com',
            to: email,
            subject: 'BoilerBuzz Email Verification',
            html: `<p>Thank you for signing up! Please use the following token to verify your email:</p>
                   <p><strong>${verificationToken}</strong></p>`
        };
        
        transporter.sendMail(mailOptions, (error, info) => {
            if (error) {
                console.error('Error sending email: ', error);
                return res.status(500).json({ message: 'Error sending verification email' });
            } else {
                console.log('Verification email sent: ', info.response);
            }
        });
        
        res.status(201).json({ message: 'User registered successfully!' });
    } catch (err) {
        console.error(err);
        res.status(500).json({ message: 'Error registering user' });
    }
    
});

// Login route
router.post('/login', async (req, res) => {
    const { username, password } = req.body;
    console.log(`got login request with username: ${username} and password: ${password}`);
    
    try {
        // Check if the user exists
        const user = await User.findOne({ username });
        if (!user) {
            return res.status(400).json({ message: 'User not found' });
        }
        
        // Check if the user has verified their email
        if (!user.emailVerified) {
            return res.status(400).json({ message: 'Please verify your email first' });
        }

        // Compare the password
        const isMatch = await bcrypt.compare(password, user.password);
        if (!isMatch) {
            return res.status(400).json({ message: 'Invalid Credentials' });
        }

        // this is the jwt token for once the login fully works
        //const token = jwt.sign({ userId: user._id }, 'boilerbuzzjwt', { expiresIn: '1h' });

        res.status(200).json({ message: 'Login successful' });
    } catch (err) {
        console.error(err);
        res.status(500).json({ message: 'Error logging in user' });
    }
});

//verification route
router.post('/verify', async (req, res) => {
    const { email, verificationToken } = req.body;
    console.log(`got verification request with email: ${email} and verification: ${verificationToken}`);
    try {
        // Check if the user exists
        const user = await User.findOne({ email });
        if (!user) {
            return res.status(400).json({ message: 'No user found with that email' });
        }
        
        console.log(user.verificationToken)

        // Check if the verification token matches
        if (user.verificationToken !== verificationToken) {
            return res.status(400).json({ message: 'Invalid verification token' });
        }

        // Mark the user as verified
        user.emailVerified = true;
        user.verificationToken = null; // Remove token after successful verification
        await user.save();

        return res.status(200).json({ message: 'Account verified successfully!' });
    } catch (error) {
        console.error('Verification error:', error);
        return res.status(500).json({ message: 'Internal server error' });
    }
});

module.exports = router;
