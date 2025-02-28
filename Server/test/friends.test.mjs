// friends.test.mjs
// Tests for the friends endpoints

import { expect } from 'chai';
import request from 'supertest';
import express from 'express';
import mongoose from 'mongoose';
import friendsRouter from '../Routes/friends.js'; // Adjust the path if needed
import User from '../Models/User.js';

// Create an Express app and mount the friends router.
const app = express();
app.use(express.json());
app.use('/api/friends', friendsRouter);

describe('Friends Endpoints', function () {
  let primaryUserId, friendUserId;

  // Before tests, connect to a test database and create two test users.
  before(async function () {
    this.timeout(20000); // 20 seconds
    await mongoose.connect('mongodb+srv://skonger6:Meiners1@cluster0.ytchv.mongodb.net/Boiler_Buzz?retryWrites=true&w=majority&appName=Cluster0');
    
    
    // Clean up any previous test users.
    await User.deleteMany({ email: { $in: ["friendtest1@example.com", "friendtest2@example.com"] } });
    
    // Create primary test user.
    const primaryUser = new User({
      email: "friendtest1@example.com",
      username: "primaryuser",
      password: "password",
      friends: [] // Initially no friends.
    });
    await primaryUser.save();
    primaryUserId = primaryUser._id.toString();

    // Create friend test user.
    const friendUser = new User({
      email: "friendtest2@example.com",
      username: "frienduser",
      password: "password",
      friends: []
    });
    await friendUser.save();
    friendUserId = friendUser._id.toString();
  });

  // Clean up after tests.
  after(async function () {
    this.timeout(20000); // 20 seconds
    await User.deleteMany({ email: { $in: ["friendtest1@example.com", "friendtest2@example.com"] } });
    await mongoose.connection.close();
  });

  it('should return false for friend status when no friend added', async function () {
    const res = await request(app)
      .get(`/api/friends/status?userId=${primaryUserId}&friendId=${friendUserId}`);
    expect(res.status).to.equal(200);
    expect(res.body).to.have.property('isFriend', false);
  });

  it('should add a friend successfully', async function () {
    const res = await request(app)
      .post('/api/friends/addFriend')
      .send({ userId: primaryUserId, friendId: friendUserId });
    expect(res.status).to.equal(200);
    expect(res.body).to.have.property('success', true);
    // Check that friendUserId is now in the friends array.
    expect(res.body.friends).to.include(friendUserId);
  });

  it('should return true for friend status when friend added', async function () {
    const res = await request(app)
      .get(`/api/friends/status?userId=${primaryUserId}&friendId=${friendUserId}`);
    expect(res.status).to.equal(200);
    expect(res.body).to.have.property('isFriend', true);
  });

  it('should retrieve the friend in the friends list', async function () {
    const res = await request(app)
      .get(`/api/friends/${primaryUserId}`);
    expect(res.status).to.equal(200);
    expect(res.body).to.be.an('array');
    // Find the friend in the returned list.
    const friend = res.body.find(f => f._id === friendUserId);
    expect(friend).to.exist;
    expect(friend).to.have.property('username', 'frienduser');
  });

  it('should remove a friend successfully', async function () {
    const res = await request(app)
      .post('/api/friends/removeFriend')
      .send({ userId: primaryUserId, friendId: friendUserId });
    expect(res.status).to.equal(200);
    expect(res.body).to.have.property('success', true);
    expect(res.body.friends).to.not.include(friendUserId);
  });

  it('should return false for friend status after friend removed', async function () {
    const res = await request(app)
      .get(`/api/friends/status?userId=${primaryUserId}&friendId=${friendUserId}`);
    expect(res.status).to.equal(200);
    expect(res.body).to.have.property('isFriend', false);
  });
});
