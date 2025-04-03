// Routes/notification.js
const express = require('express');
const router = express.Router();
const User = require('../Models/User');

// GET notification preferences for a user
router.get('/friends/:userId', async (req, res) => {
    try {
      const user = await User.findById(req.params.userId).select('friends');
  
      if (!user) {
        return res.status(404).json({ message: "User not found" });
      }
  
      const friends = await User.find(
        { _id: { $in: user.friends } },
        { _id: 1, username: 1 }
      );
  
      const friendList = friends.map(friend => ({
        id: friend._id,
        name: friend.username
      }));
  
      res.status(200).json(friendList);
    } catch (error) {
      console.error("Error fetching simplified friend list:", error);
      res.status(500).json({ message: "Internal server error" });
    }
  });
  
  module.exports = router;

  // GET notification preferences for a user
router.get('/:userId', async (req, res) => {
    try {
        const user = await User.findById(req.params.userId).select('notificationPreferences').lean();
        if (!user) {
            return res.status(404).json({ message: "User not found" });
        }

        res.status(200).json(user.notificationPreferences);

    } catch (error) {
        console.error("Error fetching notification preferences:", error);
        res.status(500).json({ message: "Internal server error" });
    }
});

  
  // PUT update notification preferences for a user
  router.put('/:userId', async (req, res) => {
    const {
      drinkSpecials,
      eventUpdates,
      eventReminders,
      announcements,
      locationBasedOffers,
      friendPosting  // object with friend IDs as keys and booleans as values.
    } = req.body;
  
    try {
      const user = await User.findById(req.params.userId);
      if (!user) {
        return res.status(404).json({ message: "User not found" });
      }
      // Update individual preferences if provided.
      if (typeof drinkSpecials !== 'undefined') {
        user.notificationPreferences.drinkSpecials = drinkSpecials;
      }
      if (typeof eventUpdates !== 'undefined') {
        user.notificationPreferences.eventUpdates = eventUpdates;
      }
      if (typeof eventReminders !== 'undefined') {
        user.notificationPreferences.eventReminders = eventReminders;
      }
      if (typeof announcements !== 'undefined') {
        user.notificationPreferences.announcements = announcements;
      }
      if (typeof locationBasedOffers !== 'undefined') {
        user.notificationPreferences.locationBasedOffers = locationBasedOffers;
      }
      if (friendPosting && typeof friendPosting === 'object') {
        for (const friendId in friendPosting) {
          user.notificationPreferences.friendPosting.set(friendId, friendPosting[friendId]);
        }
      }
      await user.save();
      res.status(200).json({ 
        message: "Notification preferences updated successfully", 
        notificationPreferences: user.notificationPreferences 
      });
    } catch (error) {
      console.error("Error updating notification preferences:", error);
      res.status(500).json({ message: "Internal server error" });
    }
  });
  
  module.exports = router;