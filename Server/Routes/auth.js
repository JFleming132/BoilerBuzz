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
const mongoose = require('mongoose');

const router = express.Router();
router.post('/update-password', async (req, res) => {
    const { userId, oldPassword, newPassword } = req.body;

    try {
        // Find the user by userId
        const user = await User.findById(userId);
        if (!user) {
            return res.status(400).json({ message: 'User not found' });
        }

        // Check if the old password matches
        const isMatch = await bcrypt.compare(oldPassword, user.password);
        if (!isMatch) {
            return res.status(400).json({ message: 'Incorrect old password' });
        }

        // Update the password
        const salt = await bcrypt.genSalt(10);
        const hashedPassword = await bcrypt.hash(newPassword, salt);
        user.password = hashedPassword;

        // Save the updated user
        await user.save();

        res.status(200).json({ message: 'Password updated successfully!' });
    } catch (err) {
        console.error(err);
        res.status(500).json({ message: 'Error updating password' });
    }
});


// Sign-up route
router.post('/signup', async (req, res) => {
    const { email, username, password } = req.body;
    
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
        
        res.status(201).json({ 
            message: 'User registered successfully!',
            userId: newUser._id
        });
    } catch (err) {
        console.error(err);
        res.status(500).json({ message: 'Error registering user' });
    }
    
});

// Login route
router.post('/login', async (req, res) => {
    const { username, password } = req.body;
    
    try {
        // Check if the user exists
        const user = await User.findOne({ username });
        if (!user) {
            return res.status(400).json({ message: 'User not found', userId: "failed", isAdmin: false  });
        }

        console.log(user.emailVerified)
        
        // Check if the user has verified their email
        if (!user.emailVerified) {
          console.log("need to verify")
          return res.status(400).json({ message: 'Please verify your email first', userId: "failed", isAdmin: false });
        }

        // Compare the password
        const isMatch = await bcrypt.compare(password, user.password);
        if (!isMatch) {
            return res.status(400).json({ message: 'Invalid Credentials', userId: "failed", isAdmin: false  });
        }

        // this is the jwt token for once the login fully works
        //const token = jwt.sign({ userId: user._id }, 'boilerbuzzjwt', { expiresIn: '1h' });

        res.status(200).json({ 
            message: 'Login successful',
            userId: user._id,
            isAdmin: user.isAdmin,
            isPromoted: user.isPromoted
         });
    } catch (err) {
        console.error(err);
        res.status(500).json({ message: 'Error logging in user' });
    }
});

//verification route
router.post('/verify', async (req, res) => {
    const { email, verificationToken } = req.body;
    try {
        // Check if the user exists
        const user = await User.findOne({ email });
        if (!user) {
            return res.status(400).json({ message: 'No user found with that email' });
        }
        
        console.log(user.verificationToken)

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

//forgot password route
router.post('/forgotPasswordCode', async (req, res) => {
    const { email } = req.body;
    try {
        // Check if the user exists
        const user = await User.findOne({ email });
        if (!user) {
            return res.status(400).json({ message: 'No user found with that email' });
        }
        
        const forgotPasswordToken = crypto.randomBytes(32).toString('hex');
        
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
            subject: 'BoilerBuzz Forgot Password',
            html: `<p>Please use the following token to change your password:</p>
                   <p><strong>${forgotPasswordToken}</strong></p>`
        };
        
        transporter.sendMail(mailOptions, (error, info) => {
            if (error) {
                console.error('Error sending email: ', error);
                return res.status(500).json({ message: 'Error sending verification email' });
            } else {
                console.log('Forgot Password email sent: ', info.response);
            }
        });
        
        
        // Mark the user as verified
        user.forgotPasswordToken = forgotPasswordToken;
        await user.save();


        return res.status(200).json({ message: 'Password Reset Has Been Sent to Your Email!' });
    } catch (error) {
        console.error('Verification error:', error);
        return res.status(500).json({ message: 'Internal server error' });
    }
});

//forgot password route
router.post('/changePassword', async (req, res) => {
    const { email, forgotPasswordCode, newPassword } = req.body;
    try {
        // Check if the user exists
        const user = await User.findOne({ email });
        if (!user) {
            return res.status(400).json({ message: 'No user found with that email' });
        }
        
        // Check if the verification token matches
        if (user.forgotPasswordToken !== forgotPasswordCode) {
            return res.status(400).json({ message: 'Invalid Code' });
        }
        
        if (!newPassword || newPassword.trim() === '') {
           return res.status(400).json({ message: 'Password cannot be empty' });
       }
        
        const hashedPassword = await bcrypt.hash(newPassword, 10);
        
        user.forgotPasswordToken = null;
        user.password = hashedPassword
        await user.save();
        return res.status(200).json({ message: 'Your Password Has Been Changed!' });
    } catch (error) {
        console.error('Verification error:', error);
        return res.status(500).json({ message: 'Internal server error' });
    }
});


// Drinks route
router.get('/drinks', async (req, res) => {
    try {
        // Explicitly switch to the `Boiler_Buzz` database
        const db = mongoose.connection.client.db('Boiler_Buzz');
        console.log("get drinks");
        
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
