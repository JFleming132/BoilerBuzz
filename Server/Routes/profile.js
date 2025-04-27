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
const UserRating = require('../Models/Rating');

const puppeteer = require('puppeteer');

router.get('/isIdentified/:userId', async (req, res) => {
  const userId = req.params.userId;

  if (!mongoose.Types.ObjectId.isValid(userId)) {
      return res.status(400).json({ error: 'Invalid user ID' });
  }

  try {
      const user = await User.findById(userId).select('isIdentified');

      if (!user) {
          return res.status(404).json({ error: 'User not found' });
      }

      return res.status(200).json({ isIdentified: user.isIdentified });
  } catch (error) {
      console.error("Error checking isIdentified status:", error);
      return res.status(500).json({ error: 'Internal server error' });
  }
});

router.get('/aliasLookup/:alias', async (req, res) => {
  const alias = req.params.alias;
  const userId = req.query.userId;

  if (!alias || !userId) {
      return res.status(400).json({ error: 'Alias and userId are required' });
  }

  let browser;

  try {
      // Step 1: Launch Puppeteer and scrape Purdue directory
      browser = await puppeteer.launch({ headless: true });
      const page = await browser.newPage();

      await page.goto('https://www.purdue.edu/directory/', { waitUntil: 'domcontentloaded' });
      await page.type('#basicSearchInput', alias);
      await page.keyboard.press('Enter');
      await new Promise(resolve => setTimeout(resolve, 2000));
      await page.waitForSelector('#results', { timeout: 7000 });

      const result = await page.evaluate(() => {
          const resultsHTML = document.querySelector('#results')?.innerHTML;
          if (!resultsHTML) return null;

          const container = document.createElement('div');
          container.innerHTML = resultsHTML;

          const getText = (selector) =>
              container.querySelector(selector)?.innerText?.trim() || null;

          return {
              name: getText('h2.cn-name'),
              alias: getText('th.icon-key + td'),
              campus: getText('th.icon-library + td'),
              school: getText('th.icon-graduation + td'),
              qualifiedName: getText('th.icon-vcard + td')
          };
      });

      await browser.close();

      if (!result) {
          return res.status(404).json({ error: 'No directory info found' });
      }

      // Step 2: Fetch user from MongoDB
      const user = await User.findById(userId);
      if (!user || !user.email) {
          return res.status(404).json({ error: 'User not found or email missing' });
      }

      const userEmail = user.email.toLowerCase();
      const userNetID = userEmail.split('@')[0]; // e.g., "jsmith" from "jsmith@purdue.edu"
      const aliasFromDirectory = result.alias?.toLowerCase() || '';
      const aliasMatch = userNetID === aliasFromDirectory;

      let identified = false;

      if (aliasMatch) {
          // ✅ Mark user as identified in the DB
          await User.findByIdAndUpdate(userId, { isIdentified: true });
          identified = true;
      }

      res.status(200).json({
          ...result,
          aliasMatch,
          userNetID,
          directoryAlias: aliasFromDirectory,
          identified
      });

  } catch (err) {
      if (browser) await browser.close();
      console.error('Error during alias lookup:', err);
      res.status(500).json({ error: 'Failed to fetch data from Purdue Directory' });
  }
});


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
        console.log("Why are we here")
        const user = await User.findById(req.params.userId).select('username bio profilePicture isAdmin isBanned isPromoted rating ratingCount'); //TODO: Add isPromoted status
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

router.post('/banUser', async (req, res) => {
    const { adminId, friendId } = req.body;
    
    // Validate that the IDs are valid ObjectIds.
    if (!mongoose.Types.ObjectId.isValid(adminId) || !mongoose.Types.ObjectId.isValid(friendId)) {
        return res.status(400).json({ error: 'Invalid user Id(s)' });
    }
    
    try {
        // Find the admin user and verify they have admin privileges.
        const adminUser = await User.findById(adminId);
        if (!adminUser || !adminUser.isAdmin) {
            return res.status(403).json({ error: "Not authorized" });
        }
        
        // Find the target user (friend) whose ban status is to be toggled.
        const friendUser = await User.findById(friendId);
        if (!friendUser) {
            return res.status(404).json({ error: "User not found" });
        }
        
        // Toggle the ban status.
        friendUser.isBanned = !friendUser.isBanned;
        await friendUser.save();
        
        res.status(200).json({ success: true, isBanned: friendUser.isBanned });
    } catch (error) {
        console.error("Error toggling ban status:", error);
        res.status(500).json({ error: "Internal server error" });
    }
});

router.post('/promote', async (req, res) => {
    const { adminId, friendId } = req.body;
    
    // Validate that the IDs are valid ObjectIds.
    if (!mongoose.Types.ObjectId.isValid(adminId) || !mongoose.Types.ObjectId.isValid(friendId)) {
        return res.status(400).json({ error: 'Invalid user Id(s)' });
    }
    
    try {
        // Find the admin user and verify they have admin privileges.
        const adminUser = await User.findById(adminId);
        if (!adminUser || !adminUser.isAdmin) {
            return res.status(403).json({ error: "Not authorized" });
        }
        
        // Find the target user (friend) whose ban status is to be toggled.
        const friendUser = await User.findById(friendId);
        if (!friendUser) {
            return res.status(404).json({ error: "User not found" });
        }
        
        // Toggle the ban status.
        friendUser.isPromoted = !friendUser.isPromoted;
        await friendUser.save();
        
        res.status(200).json({ success: true, isPromoted: friendUser.isPromoted });
    } catch (error) {
        console.error("Error toggling promotion status:", error);
        res.status(500).json({ error: "Internal server error" });
    }
});

// POST endpoint to delete a user.
router.post('/deleteUser', async (req, res) => {
    const { adminId, friendId } = req.body;
    
    // Validate that the IDs are valid ObjectIds.
    if (!mongoose.Types.ObjectId.isValid(adminId) || !mongoose.Types.ObjectId.isValid(friendId)) {
        return res.status(400).json({ error: 'Invalid user Id(s)' });
    }
    
    try {
        // Find the admin user and verify that they have admin privileges.
        const adminUser = await User.findById(adminId);
        if (!adminUser || !adminUser.isAdmin) {
            return res.status(403).json({ error: "Not authorized" });
        }
        
        // Delete all ratings where the ratedUserId matches the user to be deleted.
        await UserRating.deleteMany({ ratedUserId: friendId });
        
        // Delete the target user.
        const deletedUser = await User.findByIdAndDelete(friendId);
        if (!deletedUser) {
            return res.status(404).json({ error: "User not found" });
        }
        
        res.status(200).json({ success: true, message: "User deleted successfully." });
    } catch (error) {
        console.error("Error deleting user:", error);
        res.status(500).json({ error: "Internal server error" });
    }
});

module.exports = router;
