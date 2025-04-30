//
//  drinks.js
//  BoilerBuzz
//
//  Created by Matt Zlatniski on 2/16/25.
//
const express = require('express');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const User = require('../Models/User');
const nodemailer = require('nodemailer');
const crypto = require('crypto');
const mongoose = require('mongoose');
const { ObjectId } = require('mongodb');

const Drink = require('../Models/Drink');

const router = express.Router();

router.post('/toggleTriedDrink', async (req, res) => {
    const { userId, objectId, rating } = req.body;

   

    const session = await mongoose.startSession(); // Start transaction session
    session.startTransaction();

    try {
        const user = await User.findById(userId).session(session);
        if (!user) {
            await session.abortTransaction();
            return res.status(404).json({ error: 'User not found' });
        }

        const drink = await Drink.findById(objectId).session(session);
        if (!drink) {
            await session.abortTransaction();
            return res.status(404).json({ error: 'Drink not found' });
        }

        let removedRating = null;
        let isAddingRating = false;

        // Check if the drink already exists in triedDrinks
        const existingDrinkIndex = user.triedDrinks.findIndex(drink => drink.objectId === objectId);

        if (existingDrinkIndex !== -1) {
            // If the drink exists, remove it and its rating
            removedRating = user.triedDrinks[existingDrinkIndex].rating;
            user.triedDrinks.splice(existingDrinkIndex, 1);

            // Remove rating from drink's rating list
            await Drink.updateOne(
                { _id: objectId },
                { $pull: { ratings: { userId } } },
                { session }
            );
        } else {
            // If the drink does not exist, add it and its rating
            user.triedDrinks.push({ objectId: objectId, rating: rating });

            // Add rating to drink's rating list
            await Drink.updateOne(
                { _id: objectId },
                { $push: { ratings: { userId, rating } } },
                { session }
            );

            isAddingRating = true;
        }

        await user.save({ session });

        // Fetch updated drink data with the latest ratings
        const updatedDrink = await Drink.findById(objectId).session(session);

        // Calculate new average rating from the ratings array
        const totalRating = updatedDrink.ratings.reduce((sum, r) => sum + r.rating, 0);
        const newRatingCount = updatedDrink.ratings.length;
        const newAverageRating = newRatingCount > 0 ? totalRating / newRatingCount : 0;

        // Update the drink document with the new average rating and rating count
        await Drink.updateOne(
            { _id: objectId },
            { $set: { averageRating: newAverageRating} },
            { session }
        );

        await session.commitTransaction();
        session.endSession();
        

        return res.json({
            success: true,
            averageRating: newAverageRating
        });

    } catch (error) {
        await session.abortTransaction();
        session.endSession();
        console.error('Error toggling tried drink:', error);
        return res.status(500).json({ error: 'Internal server error' });
    }
});




// Fetch tried drinks for a user
router.get('/triedDrinks/:userId', async (req, res) => {
  const { userId } = req.params;

  if (!mongoose.Types.ObjectId.isValid(userId)) {
      return res.status(400).json({ error: 'Invalid user Id' });
  }

  try {
      const user = await User.findById(userId);

      if (!user) {
          return res.status(404).json({ error: 'User not found' });
      }

      // Return the full triedDrinks array with name + rating
      return res.json({ triedDrinks: user.triedDrinks });

  } catch (error) {
      console.error('Error fetching tried drinks:', error);
      return res.status(500).json({ error: 'Internal server error' });
  }
});

router.get('/isDrinkFavorite', async (req, res) => {
    console.log("Incoming Request to /isDrinkTried")
    const userId = req.query.userId
    const drinkId = req.query.drinkId
    const userObjId = new ObjectId(userId)
    if (!mongoose.Types.ObjectId.isValid(userId)) {
        console.log("Invalid User Id: " + userId)
        return res.status(400).json({ error: 'Invalid user Id' })
    }
    try {
        const triedMatches = await User.aggregate(
                                                  [
                                                   [
                                                       {
                                                         $match: {
                                                           _id: userObjId
                                                         }
                                                       },
                                                       { $project: { favoriteDrinks: 1 } },
                                                       { $unwind: { path: '$favoriteDrinks' } },
                                                       { $match: { favoriteDrinks: drinkId } },
                                                     ],
                                                    ],
          { maxTimeMS: 60000, allowDiskUse: true }
        );
        //console.log(userId + " with drink " + drinkId + " returns:")
        //console.log(triedMatches)
        let calculatedResponse;
        if (triedMatches.length > 0) {
            calculatedResponse = {isDrinkTried: true}
        } else {
            calculatedResponse = {isDrinkTried: false}
        }
        res.json(calculatedResponse)
    } catch (error) {
        console.error('Error fetching drink\'s tried status by user:', error);
        return res.status(500).json({ error: 'Internal server error' })
    }
});

// GET endpoint to retrieve favorite drinks for a given user
router.get('/favoriteDrinks/:userId', async (req, res) => {
    try {
      // Use the same database as your /drinks endpoint
      const db = mongoose.connection.client.db('Boiler_Buzz');
      
      // Retrieve the user document by the given userId
      const user = await User.findById(req.params.userId);
      if (!user) {
        return res.status(404).json({ error: "User not found" });
      }
      
      // Extract the favorite drink IDs from the user document
      const favoriteDrinkIds = user.favoriteDrinks || [];
      
      // If no favorites, return an empty array
      if (favoriteDrinkIds.length === 0) {
        return res.status(200).json([]);
      }


      const convertedIDs = favoriteDrinkIds.map(item => parseInt(item, 10));
      // Query the drinks collection for drinks whose drinkID (which is stored as an integer) is in the favoriteDrinkIds array
      const drinks = await db.collection('drinks').find({ drinkID: { $in: convertedIDs } }).toArray();
      
      // Return the retrieved drinks as JSON
      res.status(200).json(drinks);
    } catch (error) {
      console.error("Error fetching favorite drinks:", error.message);
      res.status(500).json({ error: "Failed to fetch favorite drinks. Please try again later." });
    }
});
  

// POST endpoint to add a drink to a user's favorites
router.post('/toggleFavoriteDrink', async (req, res) => {
    const { userId, drinkId } = req.body;
    const drinkIdStr = drinkId.toString();

    if (!mongoose.Types.ObjectId.isValid(userId)) {
        return res.status(400).json({ error: 'Invalid user Id' });
    }

    try {
        // Use the same database as your /drinks endpoint
        const db = mongoose.connection.client.db('Boiler_Buzz');
      
        // Retrieve the user document by the given userId
        const user = await User.findById(userId);
        if (!user) {
          return res.status(404).json({ error: "User not found" });
        }
      
        // Extract the favorite drink IDs from the user document
        const favoriteDrinkIds = user.favoriteDrinks || [];
        // If the drinkId is already in the favorites, remove it
        if (favoriteDrinkIds.includes(drinkIdStr)) {
          user.favoriteDrinks = favoriteDrinkIds.filter(id => id !== drinkIdStr);
        } else {
          // Otherwise, add the drinkId to the favorites
          user.favoriteDrinks.push(drinkIdStr);
        }
      
        // Update the user document in the database
        await user.save();
        // Return a success message
        return res.status(200).json({ success: true });
    } catch (error) {
        console.error('Error toggling favorite drink:', error);
        return res.status(500).json({ error: 'Internal server error' });
    }
});

module.exports = router;
