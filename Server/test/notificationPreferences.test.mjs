// notificationPreferences.test.mjs

import { expect } from 'chai';
import request from 'supertest';
import express from 'express';
import mongoose from 'mongoose';
import notificationRoutes from '../Routes/notification.js'; // Adjust path if needed
import User from '../Models/User.js';

// Create an Express app and mount the notification routes on /api/notification.
const app = express();
app.use(express.json());
app.use('/api/notification', notificationRoutes);

describe('Notification Preferences Endpoints', function () {
  this.timeout(10000);

  // We'll use this test user for our tests.
  let testUserId;
  let friendUserId;

  // Before tests, connect to the database and create a test user with some notification preferences and friends.
  before(async function () {
    await mongoose.connect('mongodb+srv://skonger6:Meiners1@cluster0.ytchv.mongodb.net/Boiler_Buzz?retryWrites=true&w=majority&appName=Cluster0');

    // Clean up any previous test users.
    await User.deleteMany({ email: { $in: ["notiftest@example.com", "friendnotiftest@example.com"] } });
    
    // Create a friend test user.
    const friendUser = new User({
      email: "friendnotiftest@example.com",
      username: "friendnotif",
      password: "password"
    });
    await friendUser.save();
    friendUserId = friendUser._id.toString();

    // Create the test user with initial notificationPreferences.
    // For this example, we'll assume notificationPreferences is stored as a plain object.
    const testUser = new User({
      email: "notiftest@example.com",
      username: "notifuser",
      password: "password",
      friends: [friendUserId],
      notificationPreferences: {
        drinkSpecials: false,
        eventUpdates: false,
        eventReminders: false,
        announcements: false,
        locationBasedOffers: false,
        // Initially set friend notifications to false.
        friendPosting: { [friendUserId]: false }
      }
    });
    await testUser.save();
    testUserId = testUser._id.toString();
  });

  // Clean up after tests.
  after(async function () {
    await User.deleteMany({ email: { $in: ["notiftest@example.com", "friendnotiftest@example.com"] } });
    await mongoose.connection.close();
  });

  describe('GET /api/notification/friends/:userId', function () {
    it('should return the friend list for notifications', async function () {
      const res = await request(app)
        .get(`/api/notification/friends/${testUserId}`)
        .expect(200);
      
      expect(res.body).to.be.an('array');
      // The friend list should contain the friendUserId.
      const friend = res.body.find(f => f.id === friendUserId || f.id.toString() === friendUserId);
      expect(friend).to.exist;
      expect(friend).to.have.property('name');
    });
  });

  describe('GET /api/notification/:userId', function () {
    it('should retrieve the notification preferences for the user', async function () {
      const res = await request(app)
        .get(`/api/notification/${testUserId}`)
        .expect(200);
      
      expect(res.body).to.be.an('object');
      expect(res.body).to.have.property('drinkSpecials');
      expect(res.body).to.have.property('friendPosting');
      // Check that the friendPosting object contains our friend with the initial value false.
      expect(res.body.friendPosting).to.have.property(friendUserId);
      expect(res.body.friendPosting[friendUserId]).to.equal(false);
    });
  });

  describe('PUT /api/notification/:userId', function () {
    it('should update the notification preferences for the user', async function () {
      // Define new preferences. For example, enable drinkSpecials and notifications for our friend.
      const updatedPrefs = {
        drinkSpecials: true,
        eventUpdates: true,
        eventReminders: false,
        announcements: true,
        locationBasedOffers: false,
        friendPosting: { [friendUserId]: true }
      };

      const res = await request(app)
        .put(`/api/notification/${testUserId}`)
        .send(updatedPrefs)
        .expect(200);

      expect(res.body).to.have.property('message', 'Notification preferences updated successfully');
      expect(res.body).to.have.property('notificationPreferences');
      const prefs = res.body.notificationPreferences;
      expect(prefs).to.have.property('drinkSpecials', true);
      expect(prefs).to.have.property('eventUpdates', true);
      expect(prefs).to.have.property('announcements', true);
      // Check friendPosting. Depending on how it's stored, it might be an object.
      expect(prefs.friendPosting).to.have.property(friendUserId);
      expect(prefs.friendPosting[friendUserId]).to.equal(true);
    });
  });
});
