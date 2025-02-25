//
//  profile.js
//  BoilerBuzz
//
//  Created by Patrick Barry on 2/13/25.
//

const express = require('express');
const User = require('../Models/User');
const router = express.Router();


// Route to GET user profile details (Username & Bio) using the MongoDB _id
router.get('/:userId', async (req, res) => {
    try {
        console.log(`got request for user ${req.params.userId}`);
        const user = await User.findById(req.params.userId).select('username bio profilePicture');
        if (!user) {
            return res.status(404).json({ message: "User not found" });
        }
        res.status(200).json(user);
    } catch (error) {
        console.error("Error fetching profile:", error);
        res.status(500).json({ message: "Internal server error" });
    }
});

// Route to UPDATE user profile (Username & Bio) not pic yet
router.put('/:userId', async (req, res) => {
    const { username, bio, profilePicture } = req.body;
    console.log(`Received profile update request for user ${req.params.userId}`);

    try {
        // Check if the username is already taken by another user
        const existingUser = await User.findOne({ username });
        if (existingUser && existingUser._id.toString() !== req.params.userId) {
            return res.status(400).json({ message: "Username is already taken" });
        }
        
        // Check to make sure username is not empty
        if (!username || username.trim() === '') {
            return res.status(400).json({ message: "Username cannot be empty" });
        }
        //console.log(`attempting to update userid ${req.params.userId} with ${req.body.profilePicture}`)
        const updatedUser = await User.findByIdAndUpdate(
            req.params.userId,
            { username, bio, profilePicture },
            { new: true, runValidators: true }
        );

        if (!updatedUser) {
            return res.status(404).json({ message: "User not found" });
        }

        res.status(200).json({ message: "Profile updated successfully!", updatedUser });
    } catch (error) {
        console.error("Error updating profile:", error);
        res.status(500).json({ message: "Internal server error" });
    }
});

module.exports = router;
