//
//  auth.test.mjs
//  BoilerBuzz
//
//  Created by Matt Zlatniski on 2/27/25.
//
import { expect } from 'chai';
import request from 'supertest';
import express from 'express';
import mongoose from 'mongoose';
import bcrypt from 'bcryptjs';
import authRouter from '../routes/auth.js';
import User from '../Models/User.js';

const app = express();
app.use(express.json());
app.use('/api/auth', authRouter);

describe('Auth Endpoints', function () {
  let testUserId;
  let testUser;

  before(async function () {
    await mongoose.connect('mongodb+srv://skonger6:Meiners1@cluster0.ytchv.mongodb.net/Boiler_Buzz?retryWrites=true&w=majority&appName=Cluster0');
    // Create a test user to use for update-password and login.
    testUser = new User({
      email: "authtest@example.com",
      username: "authtestuser",
      password: await bcrypt.hash("oldpassword", 10),
      emailVerified: true
    });
    await testUser.save();
    testUserId = testUser._id.toString();
  });

  after(async function () {
    await User.deleteOne({ _id: testUserId });
    await mongoose.connection.close();
  });

  it('should update the password', async function () {
    const payload = {
      userId: testUserId,
      oldPassword: "oldpassword",
      newPassword: "newpassword"
    };

    const res = await request(app)
      .post('/api/auth/update-password')
      .send(payload);

    expect(res.status).to.equal(200);
    expect(res.body).to.have.property("message", "Password updated successfully!");

    const updatedUser = await User.findById(testUserId);
    const isMatch = await bcrypt.compare("newpassword", updatedUser.password);
    expect(isMatch).to.be.true;
  });

  it('should sign up a new user', async function () {
    const payload = {
      email: "signuptest@purdue.edu",
      username: "signuptestuser",
      password: "signupPassword123"
    };

    const res = await request(app)
      .post('/api/auth/signup')
      .send(payload);

    expect(res.status).to.equal(201);
    expect(res.body).to.have.property("message", "User registered successfully!");
    expect(res.body).to.have.property("userId");

    // Clean up the created user.
    await User.deleteOne({ _id: res.body.userId });
  });
    
    it('should return 400 when signing up with a non-purdue.edu email', async function () {
      const payload = {
        email: "invalid@example.com",  // not a purdue.edu email
        username: "invaliduser",
        password: "signupPassword123"
      };

      const res = await request(app)
        .post('/api/auth/signup')
        .send(payload);

      expect(res.status).to.equal(400);
      expect(res.body).to.have.property("message", "Email must be a purdue.edu email");
    });


  it('should login a user', async function () {
    const payload = {
      username: "authtestuser",
      password: "newpassword" // using the updated password from the update test
    };

    const res = await request(app)
      .post('/api/auth/login')
      .send(payload);

    expect(res.status).to.equal(200);
    expect(res.body).to.have.property("message", "Login successful");
    expect(res.body).to.have.property("userId", testUserId);
  });

  it('should verify a user', async function () {
    // Create a new unverified user with a verification token.
    const token = "testtoken123";
    const unverifiedUser = new User({
      email: "verifytest@example.com",
      username: "verifytestuser",
      password: await bcrypt.hash("password123", 10),
      emailVerified: false,
      verificationToken: token
    });
    await unverifiedUser.save();

    const res = await request(app)
      .post('/api/auth/verify')
      .send({ email: "verifytest@example.com", verificationToken: token });

    expect(res.status).to.equal(200);
    expect(res.body).to.have.property("message", "Account verified successfully!");

    await User.deleteOne({ _id: unverifiedUser._id });
  });

  it('should send a forgot password code', async function () {
    const payload = { email: testUser.email };

    const res = await request(app)
      .post('/api/auth/forgotPasswordCode')
      .send(payload);

    expect(res.status).to.equal(200);
    expect(res.body).to.have.property("message", "Password Reset Has Been Sent to Your Email!");

    const updatedUser = await User.findById(testUserId);
    expect(updatedUser.forgotPasswordToken).to.be.a('string');
  });
});
