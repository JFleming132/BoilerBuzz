//
//  profile.js
//  BoilerBuzz
//
//  Created by Patrick Barry on 2/13/25.
//

const express = require('express');
const User = require('../Models/User');
const router = express.Router();
const mongoose = require('mongoose');
const { ObjectId } = require('mongodb');

router.get('/random', async (req, res) => {
    try {
      // Exclude current user's ID if provided as a query parameter.
      const excludeId = req.query.exclude;
  
      const db = req.app.locals.db || mongoose.connection.client.db('Boiler_Buzz');
  
      // Build the filter: if excludeId is provided, exclude that user.
      let filter = {};
      if (excludeId && mongoose.Types.ObjectId.isValid(excludeId)) {
        filter = { _id: { $ne: new ObjectId(excludeId) } };
      }

  
      // Use aggregation to sample one random user that matches the filter.
      const randomUserArray = await db.collection('users').aggregate([
        { $match: filter },
        { $sample: { size: 1 } }
      ]).toArray();
  
      if (randomUserArray.length === 0) {
        return res.status(404).json({ error: "No user found" });
      }
  
      // Return the random user's ID (or full profile if needed)
      const randomUser = randomUserArray[0];
      // For simplicity, return _id and username.
      randomUser._id = randomUser._id.toString();
      res.status(200).json({ _id: randomUser._id, username: randomUser.username });
    } catch (error) {
      console.error("Error fetching random profile:", error.message);
      res.status(500).json({ error: "Failed to fetch random profile." });
    }
  });
// Route to GET user profile details (Username & Bio) using the MongoDB _id
router.get('/:userId', async (req, res) => {
    try {
        console.log("Why are we here") //...like existentially?
        const user = await User.findById(req.params.userId).select('username bio profilePicture isAdmin');
        if (!user) {
            return res.status(404).json({ message: "User not found" });
        }
        //console.log(user) < spams console, but useful debug msg
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
