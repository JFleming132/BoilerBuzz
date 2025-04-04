const express = require('express');
const router = express.Router();
const mongoose = require('mongoose');
const { ObjectId } = require('mongodb');
const User = require('../Models/User');

// GET endpoint to search for users by username
router.get('/search', async (req, res) => {
    try {
      const { username, exclude } = req.query;
      if (!username) {
        return res.status(400).json({ error: "Username query parameter is required." });
      }
  
      // Use a case-insensitive regex to find matching usernames.
      const regex = new RegExp(username, "i");
  
      const filter = { username: { $regex: regex } };

        // If an exclude parameter is provided and it's a valid ObjectId, exclude that user.
      if (exclude && mongoose.Types.ObjectId.isValid(exclude)) {
        filter._id = { $ne: new mongoose.Types.ObjectId(exclude) };
        }
    
    
      let friendIds = [];
      if (exclude && mongoose.Types.ObjectId.isValid(exclude)) {
          const currentUser = await User.findById(exclude).select('friends');
          if (currentUser && currentUser.friends && currentUser.friends.length > 0) {
            friendIds = currentUser.friends;
            // Extend the _id filter with a $nin condition.
            filter._id = Object.assign({}, filter._id, { 
              $nin: friendIds.map(id => new mongoose.Types.ObjectId(id))
            });
          }
        }

        // Query the 'users' collection using Mongoose.
      const users = await User.find(filter)
        .select('username profilePicture')
        .limit(20);
  
      if (!users || users.length === 0) {
        return res.status(200).json([]);
      }
  
      // Convert ObjectIds to strings and format the response.
      const sanitizedUsers = users.map(user => ({
        _id: user._id.toString(),
        username: user.username,
        profilePicture: user.profilePicture || "https://example.com/default-profile.png"
      }));
  
      res.status(200).json(sanitizedUsers);
    } catch (error) {
      console.error("Error searching for users:", error.message);
      res.status(500).json({ error: "Failed to search for users. Please try again later." });
    }
});

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

        // If the user has notificationPreferences and a friendPosting object, remove the friend.
        if (user.notificationPreferences && user.notificationPreferences.friendPosting) {
            // If friendPosting is stored as a Map, use delete; otherwise, as an object, remove the key.
            if (user.notificationPreferences.friendPosting instanceof Map) {
                user.notificationPreferences.friendPosting.delete(friendId);
            } else {
                delete user.notificationPreferences.friendPosting[friendId];
            }
        }
        
        // Save the updated user document.
        await user.save({ validateBeforeSave: false });
        
        res.status(200).json({ success: true, friends: user.friends });
    } catch (error) {
        console.error('Error removing friend:', error);
        res.status(500).json({ error: 'Internal server error' });
    }
});
 
module.exports = router;
