const mongoose = require('mongoose');

const ratingSchema = new mongoose.Schema({
    // The ID of the user being rated.
  ratedUserId: {
    type: String,
    ref: 'User',
    required: true
  },
  // The ID of the user who submitted the rating.
  raterUserId: {
    type: String,
    ref: 'User',
    required: true
  },
  // The rating value, e.g., 0.0, 0.5, 1.0, ... up to 5.0.
  rating: {
    type: Number,
    required: true,
    min: 0,
    max: 5
  },
  // Optional feedback text.
  feedback: {
    type: String,
    default: ""
  },
  // Timestamp for when the rating was submitted.
  createdAt: {
    type: Date,
    default: Date.now
  }
});

ratingSchema.index({ ratedUserId: 1, raterUserId: 1 }, { unique: true });

const UserRating = mongoose.model('UserRating', ratingSchema);

module.exports = UserRating;