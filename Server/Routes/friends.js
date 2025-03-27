const express = require('express');
const router = express.Router();
const mongoose = require('mongoose');
const { ObjectId } = require('mongodb');
const User = require('../Models/User'); // if you're using Mongoose, though we use the native client here


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
      const isFriend = user.friends && user.friends.includes(friendId);
      res.status(200).json({ isFriend });
    } catch (error) {
      console.error("Error fetching friend status:", error.message);
      res.status(500).json({ error: "Failed to fetch friend status. Please try again later." });
    }
  });

// GET endpoint to retrieve the friends list for a given user
router.get('/:userId', async (req, res) => {
  try {
    // Access the 'Boiler_Buzz' database using the MongoDB client
    const db = req.app.locals.db || mongoose.connection.client.db('Boiler_Buzz');

    // log "Getting friends of id: {id}"
    console.log(`Getting friends of id: ${req.params.userId}`);

    // Find the user by their _id (converted to ObjectId)
    const user = await db.collection('users').findOne({ _id: new ObjectId(req.params.userId) });
    if (!user) {
      return res.status(404).json({ error: "User not found" });
    }

    // Extract the friends array from the user document (if it exists)
    const friendIds = user.friends || [];
    
    // If there are no friends, return an empty array
    if (friendIds.length === 0) {
      return res.status(200).json([]);
    }

    // Ensure friendIds is an array of strings
    if (!Array.isArray(friendIds)) {
      return res.status(400).json({ error: "Invalid friend IDs format" });
    }
    
    // Convert friendIds (assumed stored as strings) to ObjectId instances for the query
    const objectIds = friendIds.map(id => new ObjectId(String(id)));

    
    // Query the 'users' collection for friend documents
    let friends = await db.collection('users').find({ _id: { $in: objectIds } }).toArray();

    if (!friends || friends.length === 0) {
      return res.status(404).json({ error: "No friends found" });
    }

    // Format and send only the _id, and username
    friends.forEach(friend => {
      friend._id = friend._id.toString(); // Convert ObjectId to string
    });
    friends = friends.map(friend => ({
        _id: friend._id,
        username: friend.username,
        profilePicture: friend.profilePicture || "https://example.com/default-profile.png", // Default profile picture URL
        }));

    // Return the list of friends as JSON
    res.status(200).json(friends);
  } catch (error) {
    console.error("Error fetching friends:", error.message);
    res.status(500).json({ error: "Failed to fetch friends. Please try again later." });
  }
});


router.post('/addFriend', async (req, res) => {
    const { userId, friendId } = req.body;
    
    // Validate that the user IDs are valid ObjectIds if stored that way.
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
        if (!user.friends) {
            user.friends = [];
        }
        
        // Add friendId to the user's friends list if it's not already there.
        if (!user.friends.includes(friendId)) {
            user.friends.push(friendId);
        }
        
        // Save the updated user document.
        await user.save({ validateBeforeSave: false });
        
        res.status(200).json({ success: true, friends: user.friends });
    } catch (error) {
        console.error('Error adding friend:', error);
        res.status(500).json({ error: 'Internal server error' });
    }
});

// POST endpoint to remove a friend
router.post('/removeFriend', async (req, res) => {
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
        if (!user.friends) {
            user.friends = [];
        }
        
        // Remove friendId from the user's friends array.
        user.friends = user.friends.filter(id => id.toString() !== friendId);
        
        // Save the updated user document.
        await user.save({ validateBeforeSave: false });
        
        res.status(200).json({ success: true, friends: user.friends });
    } catch (error) {
        console.error('Error removing friend:', error);
        res.status(500).json({ error: 'Internal server error' });
    }
});

//TODO: Write function to block user (add user to current user's block list in database)
//I think we can just do the same thing for friends but edit which array we add it to
//make sure unblock friends gets updated too
 
router.post('/block', async (req, res) => {
 const { userId, friendId } = req.body;
 
 // Validate that the user IDs are valid ObjectIds if stored that way.
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
     
     // Add friendId to the user's friends list if it's not already there.
     if (!user.blockedUserIDs.includes(friendId)) {
         user.blockedUserIDs.push(friendId);
     }
     
     // Save the updated user document.
     await user.save({ validateBeforeSave: false });
     
     res.status(200).json({ success: true, friends: user.friends });
 } catch (error) {
     console.error('Error blocking:', error);
     res.status(500).json({ error: 'Internal server error' });
 }
});

// POST endpoint to remove a friend
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

module.exports = router;
