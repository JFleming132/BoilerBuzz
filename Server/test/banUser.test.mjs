// banUser.test.mjs
import { expect } from 'chai';
import request from 'supertest';
import express from 'express';
import mongoose from 'mongoose';
import friendsRouter from '../Routes/profile.js'; // Adjust path if needed
import User from '../Models/User.js';

// Create an Express app and mount the friends router.
const app = express();
app.use(express.json());
app.use('/api/friends', friendsRouter);

describe('Ban User Endpoint', function () {
  let adminUserId;
  let normalUserId;

  before(async function () {
    this.timeout(20000); // Increase timeout for database connection and setup.
    await mongoose.connect('mongodb+srv://skonger6:Meiners1@cluster0.ytchv.mongodb.net/Boiler_Buzz?retryWrites=true&w=majority&appName=Cluster0');
    

    // Clean up any previous test users.
    await User.deleteMany({ email: { $in: ["banadmintest@example.com", "banusertest@example.com"] } });
    
    // Create an admin user.
    const adminUser = new User({
      email: "banadmintest@example.com",
      username: "banadmin",
      password: "password",
      isAdmin: true,
      isBanned: false,
    });
    await adminUser.save();
    adminUserId = adminUser._id.toString();
    
    // Create a normal user.
    const normalUser = new User({
      email: "banusertest@example.com",
      username: "banuser",
      password: "password",
      isAdmin: false,
      isBanned: false,
    });
    await normalUser.save();
    normalUserId = normalUser._id.toString();
  });

  after(async function () {
    await User.deleteMany({ email: { $in: ["banadmintest@example.com", "banusertest@example.com"] } });
    await mongoose.connection.close();
  });

  it('should ban a user when an admin calls the endpoint', async function () {
    // Admin bans normal user.
    const res = await request(app)
      .post('/api/friends/banUser')
      .send({ adminId: adminUserId, friendId: normalUserId });
    
    expect(res.status).to.equal(200);
    expect(res.body).to.have.property('success', true);
    expect(res.body).to.have.property('isBanned', true);
    
    // Verify from the database.
    const friend = await User.findById(normalUserId);
    expect(friend.isBanned).to.be.true;
  });

  it('should unban a user when an admin calls the endpoint again', async function () {
    // Admin toggles ban status again to unban.
    const res = await request(app)
      .post('/api/friends/banUser')
      .send({ adminId: adminUserId, friendId: normalUserId });
    
    expect(res.status).to.equal(200);
    expect(res.body).to.have.property('success', true);
    expect(res.body).to.have.property('isBanned', false);
    
    // Verify from the database.
    const friend = await User.findById(normalUserId);
    expect(friend.isBanned).to.be.false;
  });

  it('should return 403 when a non-admin tries to ban a user', async function () {
    // Normal user (non-admin) attempts to ban the admin.
    const res = await request(app)
      .post('/api/friends/banUser')
      .send({ adminId: normalUserId, friendId: adminUserId });
    
    expect(res.status).to.equal(403);
    expect(res.body).to.have.property('error', 'Not authorized');
  });
});
