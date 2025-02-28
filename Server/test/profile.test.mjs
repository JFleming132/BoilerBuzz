// profile.test.mjs
// Tests for profile GET and PUT endpoints

import { expect } from 'chai';
import request from 'supertest';
import express from 'express';
import mongoose from 'mongoose';
import profileRouter from '../Routes/profile.js';  // Adjust the path as needed
import User from '../Models/User.js';

// Create an Express app and mount the profile router.
const app = express();
app.use(express.json());
app.use('/api/profile', profileRouter);

describe('Profile Endpoints', function () {
  let testUserId;
  let testUser2Id; // Used for testing duplicate username error

  before(async function () {
    this.timeout(20000); // Increase timeout if needed
    await mongoose.connect('mongodb+srv://skonger6:Meiners1@cluster0.ytchv.mongodb.net/Boiler_Buzz?retryWrites=true&w=majority&appName=Cluster0');
    

    // Clean up any previous test users with these emails.
    await User.deleteMany({
      email: { $in: ["profiletest@example.com", "profiletest2@example.com"] },
    });

    // Create a test user for profile fetching/updating.
    const testUser = new User({
      email: "profiletest@example.com",
      username: "profileuser",
      password: "password",
      bio: "Initial bio",
      favoriteDrinks: [],
      triedDrinks: [],
      isAdmin: false,
      isBanned: false,
    });
    await testUser.save();
    testUserId = testUser._id.toString();

    // Create a second test user to simulate duplicate username scenario.
    const testUser2 = new User({
      email: "profiletest2@example.com",
      username: "existinguser",
      password: "password",
      bio: "Existing bio",
      favoriteDrinks: [],
      triedDrinks: [],
      isAdmin: false,
      isBanned: false,
    });
    await testUser2.save();
    testUser2Id = testUser2._id.toString();
  });

  after(async function () {
    await User.deleteMany({
      email: { $in: ["profiletest@example.com", "profiletest2@example.com"] },
    });
    await mongoose.connection.close();
  });

  it('should fetch profile details for a valid user', async function () {
    const res = await request(app).get(`/api/profile/${testUserId}`);
    expect(res.status).to.equal(200);
    expect(res.body).to.have.property("username", "profileuser");
    expect(res.body).to.have.property("bio", "Initial bio");
    expect(res.body).to.have.property("isAdmin", false);
    expect(res.body).to.have.property("isBanned", false);
  });

  it('should update profile details successfully', async function () {
    const newUsername = "updateduser";
    const newBio = "Updated bio information";
    const res = await request(app)
      .put(`/api/profile/${testUserId}`)
      .send({ username: newUsername, bio: newBio });
    expect(res.status).to.equal(200);
    expect(res.body).to.have.property("message", "Profile updated successfully!");
    expect(res.body).to.have.property("updatedUser");
    expect(res.body.updatedUser).to.have.property("username", newUsername);
    expect(res.body.updatedUser).to.have.property("bio", newBio);
  });

  it('should return error if username is empty', async function () {
    const res = await request(app)
      .put(`/api/profile/${testUserId}`)
      .send({ username: "", bio: "Bio remains" });
    expect(res.status).to.equal(400);
    expect(res.body).to.have.property("message", "Username cannot be empty");
  });

  it('should return error if username is already taken', async function () {
    // Attempt to update testUser with a username already used by testUser2.
    const res = await request(app)
      .put(`/api/profile/${testUserId}`)
      .send({ username: "existinguser", bio: "New bio" });
    expect(res.status).to.equal(400);
    expect(res.body).to.have.property("message", "Username is already taken");
  });
});
