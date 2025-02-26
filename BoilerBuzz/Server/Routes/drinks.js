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

const Drink = require('../Models/Drink');

const router = express.Router();

router.post('/toggleTriedDrink', async (req, res) => {
    const { userId, objectId, rating } = req.body;

    console.log(`Got toggle drink request with userId: ${userId}, objectId: ${objectId}, rating: ${rating}`);

    const session = await mongoose.startSession(); // Start transaction session
    session.startTransaction();

    try {
        const user = await User.findById(userId).session(session);
        if (!user) {
            console.log("User not found");
            await session.abortTransaction();
            return res.status(404).json({ error: 'User not found' });
        }

        const drink = await Drink.findById(objectId).session(session);
        if (!drink) {
            console.log("Drink not found");
            await session.abortTransaction();
            return res.status(404).json({ error: 'Drink not found' });
        }

        let removedRating = null;
        let isAddingRating = false;

        // Check if the drink already exists in triedDrinks
        const existingDrinkIndex = user.triedDrinks.findIndex(drink => drink.objectId === objectId);

        if (existingDrinkIndex !== -1) {
            // If the drink exists, remove it and its rating
            console.log("Removing drink rating");
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
            console.log("Adding drink rating");
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
        
        console.log(newAverageRating)

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
    console.log("Fetch tried drinks")

    if (!mongoose.Types.ObjectId.isValid(userId)) {
        return res.status(400).json({ error: 'Invalid user Id' });
    }

    try {
        const user = await User.findById(userId);

        if (!user) {
            return res.status(404).json({ error: 'User not found' });
        }
        
        console.log(user.triedDrinks)

        // Return the full triedDrinks array with name + rating
        return res.json({ triedDrinks: user.triedDrinks });

    } catch (error) {
        console.error('Error fetching tried drinks:', error);
        return res.status(500).json({ error: 'Internal server error' });
    }
});


module.exports = router;
