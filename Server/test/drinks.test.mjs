//
//  drinks.test.mjs
//  BoilerBuzz
//
//  Created by Matt Zlatniski on 2/27/25.
//

import { expect } from 'chai';
import request from 'supertest';
import express from 'express';
import mongoose from 'mongoose';
import drinksRouter from '../routes/drinks.js';
import User from '../Models/User.js';
import Drink from '../Models/Drink.js';

const app = express();
app.use(express.json());
app.use('/api/drinks', drinksRouter);

describe('Drinks Endpoints', function () {
  let testUserId;
  const testDrinkId = 'test-drink-1';

  before(async function () {
    await mongoose.connect('mongodb+srv://skonger6:Meiners1@cluster0.ytchv.mongodb.net/Boiler_Buzz?retryWrites=true&w=majority&appName=Cluster0');
    const testUser = new User({
      email: "drinktest@example.com",
      username: "drinktestuser",
      password: "password",
      spendLimit: 200.0,
      currentSpent: 0.0,
      expenses: [],
      favoriteDrinks: [],
      triedDrinks: []
    });
    await testUser.save();
    testUserId = testUser._id.toString();

    // Create a test drink.
    const testDrink = new Drink({
      _id: testDrinkId,
      drinkID: 101,
      name: "Test Drink",
      description: "A test drink.",
      ingredients: ["Ingredient1", "Ingredient2"],
      averageRating: 0,
      ratingCount: 0,
      ratings: [],
      barServed: "Test Bar",
      category: ["Test Category"],
      calories: 100
    });
    await testDrink.save();
  });

  after(async function () {
    // Clean up: delete only the test user and test drink.
    await User.deleteOne({ _id: testUserId });
    await Drink.deleteOne({ _id: testDrinkId });
    await mongoose.connection.close();
  });

  it('should toggle tried drink (add rating) and update average rating', async function () {
    const payload = {
      userId: testUserId,
      objectId: testDrinkId,
      rating: 4
    };

    const res = await request(app)
      .post('/api/drinks/toggleTriedDrink')
      .send(payload);

    expect(res.status).to.equal(200);
    expect(res.body).to.have.property("success", true);
    expect(res.body).to.have.property("averageRating");
    // After adding a rating of 4, averageRating should be 4.
    expect(res.body.averageRating).to.equal(4);

    // Verify that the test user now has this drink in triedDrinks.
    const user = await User.findById(testUserId);
    expect(user.triedDrinks).to.be.an('array');
    expect(user.triedDrinks.length).to.equal(1);
    expect(user.triedDrinks[0]).to.have.property('objectId', testDrinkId);

    // Verify that the test drink document has the rating.
    const drink = await Drink.findById(testDrinkId);
    expect(drink.ratings).to.have.lengthOf(1);
    expect(drink.averageRating).to.equal(4);
  });

  it('should toggle tried drink (remove rating) and update average rating', async function () {
    // Remove the rating by sending the same payload again.
    const payload = {
      userId: testUserId,
      objectId: testDrinkId,
      rating: 4
    };

    const res = await request(app)
      .post('/api/drinks/toggleTriedDrink')
      .send(payload);

    expect(res.status).to.equal(200);
    expect(res.body).to.have.property("success", true);
    // With no ratings, averageRating should be 0.
    expect(res.body.averageRating).to.equal(0);

    // Verify that the user's triedDrinks array is now empty.
    const user = await User.findById(testUserId);
    expect(user.triedDrinks).to.have.lengthOf(0);

    // Verify that the test drink's ratings array is empty.
    const drink = await Drink.findById(testDrinkId);
    expect(drink.ratings).to.have.lengthOf(0);
    expect(drink.averageRating).to.equal(0);
  });
    
    //TODO: test the other endpoints in drink.js
});
