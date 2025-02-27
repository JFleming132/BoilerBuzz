//
//  spending.test.mjs
//  BoilerBuzz
//
//  Created by Matt Zlatniski on 2/27/25.
//

import { expect } from 'chai';
import request from 'supertest';
import express from 'express';
import mongoose from 'mongoose';
import spendingRouter from '../Routes/spending.js';
import User from '../Models/User.js';

// Create an Express app and mount the spending router.
const app = express();
app.use(express.json());
app.use('/api/spending', spendingRouter);

describe('Spending Endpoints', function () {
  let testUserId;

  // Before tests, connect to a test database and create a test user.
  before(async function () {
    await mongoose.connect('mongodb+srv://skonger6:Meiners1@cluster0.ytchv.mongodb.net/Boiler_Buzz?retryWrites=true&w=majority&appName=Cluster0', {
      useNewUrlParser: true,
      useUnifiedTopology: true
    });
      
  const testUser = new User({
        email: "test@example.com",
        username: "testuser",
        password: "password",
        spendLimit: 200.0,
        currentSpent: 0.0,
        expenses: [],
        favoriteDrinks: [],
        triedDrinks: []
      });
      await testUser.save();
      testUserId = testUser._id.toString();
  });

  // Clean up after tests.
  after(async function () {
    await User.deleteOne({ _id: testUserId });
    await mongoose.connection.close();
  });

  it('should add an expense for a user', async function () {
    const expense = { name: "Beer", amount: 12.50 };

    const res = await request(app)
      .post(`/api/spending/addExpense/${testUserId}`)
      .send(expense);

    expect(res.status).to.equal(200);
    expect(res.body).to.have.property("message", "Expense added successfully.");

    // Verify that the expense was added to the user.
    const user = await User.findById(testUserId);
    expect(user.expenses).to.have.lengthOf(1);
    expect(user.currentSpent).to.equal(12.50);
  });

  it('should fetch the user details', async function () {
    const res = await request(app)
      .get(`/api/spending/getUserDetails/${testUserId}`);

    expect(res.status).to.equal(200);
    expect(res.body).to.have.property("limit");
    expect(res.body).to.have.property("currentSpent");
    expect(res.body).to.have.property("expenses").that.is.an('array');
  });

  it('should edit the user spending limit', async function () {
    const newLimit = 300;

    const res = await request(app)
      .put(`/api/spending/editLimit/${testUserId}`)
      .send({ newLimit });

    expect(res.status).to.equal(200);
    expect(res.body).to.have.property("message", "Spending limit updated successfully.");

    const user = await User.findById(testUserId);
    expect(user.spendLimit).to.equal(newLimit);
  });
});

