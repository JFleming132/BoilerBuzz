//
//  blocked.js
//  BoilerBuzz
//
//  Created by Joseph Fleming on 3/27/25.
//
const express = require('express');
const router = express.Router();
const mongoose = require('mongoose');
const { ObjectId } = require('mongodb');
const User = require('../Models/User');
const Conversation = require('../Models/Conversation');
const Message = require('../Models/Messages');


router.get('/status', async (req, res) => {
    const { userId, friendId } = req.query;
    
    // Validate userId and friendId
    if (!mongoose.Types.ObjectId.isValid(userId) || !mongoose.Types.ObjectId.isValid(friendId)) {
      return res.status(400).json({ error: 'Invalid user Id(s)' });
    }
    
    try {
      // Find the current user by userId
      const user = await User.findById(userId);
      if (!user) {
        return res.status(404).json({ error: "User not found" });
      }
      
      // Check if friendId is in the user's friends array
      const isBlocked = user.blockedUserIDs && user.blockedUserIDs.includes(friendId);
      res.status(200).json({ isBlocked });
    } catch (error) {
      console.error("Error fetching blocked status:", error.message);
      res.status(500).json({ error: "Failed to fetch blocked status. Please try again later." });
    }
  });

  router.post('/block', async (req, res) => {
    const { userId, friendId, conversationId } = req.body;
  
    console.log(userId, friendId, conversationId);
  
    if (!mongoose.Types.ObjectId.isValid(userId) || !mongoose.Types.ObjectId.isValid(friendId)) {
      return res.status(400).json({ error: 'Invalid user Id(s)' });
    }
  
    try {
      const user = await User.findById(userId);
      if (!user) {
        return res.status(404).json({ error: "User not found" });
      }

      user.blockedUserIDs.push(friendId);


      console.log(user.blockedUserIDs);
      // Delete conversation only if conversationId is present
      if (conversationId && mongoose.Types.ObjectId.isValid(conversationId)) {
        const convo = await Conversation.findById(conversationId);
        if (convo) {
          await Message.deleteMany({ _id: { $in: convo.messages } });
          await convo.deleteOne();
        }
      }
  
      await user.save();
  
      res.status(200).json({ success: true, friends: user.friends });
    } catch (error) {
      console.error('Error blocking:', error);
      res.status(500).json({ error: 'Internal server error' });
    }
  });
  
  

// POST endpoint to remove a blocked user
//Note: Unused on frontend
router.post('/unblock', async (req, res) => {
 const { userId, friendId } = req.body;
 
 // Validate that the user IDs are valid ObjectIds if necessary.
 if (!mongoose.Types.ObjectId.isValid(userId) || !mongoose.Types.ObjectId.isValid(friendId)) {
     return res.status(400).json({ error: 'Invalid user Id(s)' });
 }
 
 try {
     // Find the current user by their ID.
     const user = await User.findById(userId);
     if (!user) {
         return res.status(404).json({ error: "User not found" });
     }
     
     // Ensure the friends field exists.
     if (!user.blockedUserIDs) {
         user.blockedUserIDs = [];
     }
     
     // Remove friendId from the user's friends array.
     user.blockedUserIDs = user.blockedUserIDs.filter(id => id.toString() !== friendId);
     
     // Save the updated user document.
     await user.save({ validateBeforeSave: false });
     
     res.status(200).json({ success: true, friends: user.friends });
 } catch (error) {
     console.error('Error unblocking:', error);
     res.status(500).json({ error: 'Internal server error' });
 }
});

//returns a list of all users blocked by the userID specified
router.get('/:userId', async (req, res) => {
  try {
    // Access the 'Boiler_Buzz' database using the MongoDB client
    const db = req.app.locals.db || mongoose.connection.client.db('Boiler_Buzz');

    // log "Getting friends of id: {id}"
    console.log(`Getting blocked users, params are: ${req.params}`);
    console.log(req.params);

    // Find the user by their _id (converted to ObjectId)
    const user = await db.collection('users').findOne({ _id: new ObjectId(req.params.userId) });
    if (!user) {
      return res.status(404).json({ error: "User not found" });
    }

    // Extract the blocked user ID array from the user document (if it exists)
      const blockedIds = user.blockedUserIDs || [];
    
    // If there are no blocked users, return an empty array
    if (blockedIds.length === 0) {
      return res.status(200).json([]);
    }

    // Ensure blockedIds is an array of strings
    if (!Array.isArray(blockedUserIDs)) {
      return res.status(400).json({ error: "Invalid blocked IDs format" });
    }
    
    // Convert blockedIds (assumed stored as strings) to ObjectId instances for the query
    const objectIds = blockedIds.map(id => new ObjectId(String(id)));

    
    // Query the 'users' collection for blocked user documents
    let blockedUsers = await db.collection('users').find({ _id: { $in: objectIds } }).toArray();

    if (!blockedUsers || blockedUsers.length === 0) {
      return res.status(404).json({ error: "No blocked users found" });
    }

    // Format and send only the _id, and username
    blockedUsers.forEach(blockedUser => {
      blockedUser._id = blockedUser._id.toString(); // Convert ObjectId to string
    });
    blockedUsers = blockedUsers.map(blockedUser => ({
        _id: blockedUser._id,
        username: blockedUser.username,
        profilePicture: blockedUser.profilePicture || "https://example.com/default-profile.png", // Default profile picture URL
        }));

    // Return the list of blocked users as JSON
    res.status(200).json(friends);
  } catch (error) {
    console.error("Error fetching blocked users:", error.message);
    res.status(500).json({ error: "Failed to fetch blocked users. Please try again later." });
  }
});

module.exports = router;
