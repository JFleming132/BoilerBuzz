// rating.test.mjs
import { expect } from 'chai';
import request from 'supertest';
import express from 'express';
import mongoose from 'mongoose';
import ratingRouter from '../Routes/ratings.js';
import User from '../Models/User.js';
import UserRating from '../Models/Rating.js';

// Create an Express app and mount the ratings routes on /api/ratings.
const app = express();
app.use(express.json());
app.use('/api/ratings', ratingRouter);

describe('User Rating Endpoints', function () {
  this.timeout(10000);
  let raterUserId, ratedUserId;

  // Connect to the database and create two test users.
  before(async function () {
    await mongoose.connect('mongodb+srv://skonger6:Meiners1@cluster0.ytchv.mongodb.net/Boiler_Buzz?retryWrites=true&w=majority&appName=Cluster0');

    // Clean up any previous test users.
    await User.deleteMany({ email: { $in: ["ratertest@example.com", "ratedtest@example.com", "secondratertest@example.com"] } });
    await UserRating.deleteMany({}); // Clear any existing ratings.

    // Create primary test user (rater).
    const rater = new User({
      email: "ratertest@example.com",
      username: "rateruser",
      password: "password"
    });
    await rater.save();
    raterUserId = rater._id.toString();

    // Create secondary test user (rated).
    const rated = new User({
      email: "ratedtest@example.com",
      username: "rateduser",
      password: "password"
    });
    await rated.save();
    ratedUserId = rated._id.toString();
  });

  // Clean up after tests.
  after(async function () {
    await UserRating.deleteMany({ ratedUserId });
    await User.deleteMany({ email: { $in: ["ratertest@example.com", "ratedtest@example.com", "secondratertest@example.com"] } });
    await mongoose.connection.close();
  });

  it('should submit a new rating and update the average when rated twice', async function () {
    // First, submit a rating from the rater.
    const firstRating = {
      raterUserId,
      ratedUserId,
      rating: 4,
      feedback: "Good job!"
    };

    let res = await request(app)
      .post('/api/ratings')
      .send(firstRating)
      .expect(200);

    expect(res.body).to.have.property('success', true);
    expect(res.body).to.have.property('rating', 4);

    // Submit an updated rating from the same rater.
    const secondRating = {
      raterUserId,
      ratedUserId,
      rating: 2,
      feedback: "Not so good."
    };

    res = await request(app)
      .post('/api/ratings')
      .send(secondRating)
      .expect(200);

    expect(res.body).to.have.property('success', true);
    expect(res.body).to.have.property('rating', 2);

    // Get the ratings for the rated user.
    res = await request(app)
      .get(`/api/ratings/${ratedUserId}`)
      .expect(200);

    expect(res.body).to.have.property('averageRating');
    expect(res.body).to.have.property('ratings');
    // Since the same rater updated their rating, there should be only one rating entry.
    expect(res.body.averageRating).to.equal(2);
  });

  it('should handle multiple ratings from different raters and compute the average', async function () {
    // Create a second test user as an additional rater.
    const secondRater = new User({
      email: "secondratertest@example.com",
      username: "secondrater",
      password: "password"
    });
    await secondRater.save();
    const secondRaterId = secondRater._id.toString();

    // Submit a rating from the second rater.
    const newRating = {
      raterUserId: secondRaterId,
      ratedUserId,
      rating: 4,
      feedback: "Better!"
    };

    let res = await request(app)
      .post('/api/ratings')
      .send(newRating)
      .expect(200);

    expect(res.body).to.have.property('success', true);
    expect(res.body).to.have.property('rating', 4);

    // Get the ratings for the rated user.
    res = await request(app)
      .get(`/api/ratings/${ratedUserId}`)
      .expect(200);

    expect(res.body).to.have.property('averageRating');
    // With ratings 2 (from the first rater) and 4 (from the second), the average should be 3.
    expect(res.body.averageRating).to.be.closeTo(3, 0.01);

    // Clean up: remove the second rater.
    await User.deleteOne({ _id: secondRaterId });
  });
});
