const express = require('express');
const router = express.Router();
const mongoose = require('mongoose');
const UserRating = require('../Models/Rating');
const User = require('../Models/User');

// POST endpoint to submit or update a rating
router.post('/', async (req, res) => {
  const { raterUserId, ratedUserId, rating, feedback } = req.body;

  // Validate input user IDs
  if (!raterUserId || !ratedUserId) {
    return res.status(400).json({ error: 'Invalid user IDs provided.' });
  }
  
  try {
    // Use upsert logic to update an existing rating or create a new one.
    const updatedRating = await UserRating.findOneAndUpdate(
      { raterUserId, ratedUserId },
      { rating, feedback, createdAt: Date.now() },
      { new: true, upsert: true }
    );

    // Calculate the average rating for the rated user.
    const aggregation = await UserRating.aggregate([
        { $match: { ratedUserId: ratedUserId } },
        { $group: { _id: "$ratedUserId", avgRating: { $avg: "$rating" } } }
    ]);
    
    if (aggregation.length > 0) {
        const newAvg = aggregation[0].avgRating;
        // Update the user's rating field in the User collection.
        await User.findByIdAndUpdate(ratedUserId, { rating: newAvg });
    }
  
    
    return res.status(200).json({ success: true, rating: updatedRating.rating });
  } catch (err) {
    console.error('Error submitting rating:', err);
    return res.status(500).json({ error: 'Internal server error' });
  }
});

// GET endpoint to retrieve all ratings for a given rated user, and compute the average rating.
router.get('/:ratedUserId', async (req, res) => {
  const { ratedUserId } = req.params;
  
  // Validate the rated user ID.
  if (!ratedUserId) {
    return res.status(400).json({ error: 'Invalid rated user ID.' });
  }
  
  try {
    // Retrieve all ratings for the specified rated user.
    const ratings = await UserRating.find({ ratedUserId });
    
    // If there are no ratings, return an average of 0 and an empty array.
    if (!ratings || ratings.length === 0) {
      return res.status(200).json({ averageRating: 0, ratings: [] });
    }
    
    // Calculate the average rating.
    const totalRating = ratings.reduce((sum, r) => sum + r.rating, 0);
    const averageRating = totalRating / ratings.length;
    
    // Return the average rating and the list of individual ratings (with feedback)
    return res.status(200).json({ averageRating, ratings });
  } catch (err) {
    console.error('Error retrieving ratings:', err);
    return res.status(500).json({ error: 'Internal server error' });
  }
});

module.exports = router;
