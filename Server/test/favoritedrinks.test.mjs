// favoriteDrinks.test.mjs
// Tests for the favorite drinks endpoint

import { expect } from 'chai';
import request from 'supertest';
import express from 'express';
import mongoose from 'mongoose';
import favoriteDrinksRouter from '../Routes/drinks.js'; // Adjust the path if needed
import User from '../Models/User.js';

// Create an Express app and mount the favorite drinks route.
const app = express();
app.use(express.json());
app.use('/api/drinks', favoriteDrinksRouter);

describe('Favorite Drinks Endpoints', function () {
  let testUserId;

  // Before tests, connect to a test database and create a test user.
  before(async function () {
    this.timeout(10000);
    await mongoose.connect('mongodb+srv://skonger6:Meiners1@cluster0.ytchv.mongodb.net/Boiler_Buzz?retryWrites=true&w=majority&appName=Cluster0');
    
    

    const testUser = new User({
      email: "favtest@example.com",
      username: "favtestuser",
      password: "password",
      favoriteDrinks: ["101", "102"]
    });
    await testUser.save();
    testUserId = testUser._id.toString();
  });

  // Clean up after tests.
  after(async function () {
    await User.deleteOne({ _id: testUserId });
    await mongoose.connection.close();
  });

  it('should return an array of favorite drinks when favorites exist', async function () {
    // This endpoint should return an array of drink objects for the given testUserId.
    const res = await request(app).get(`/api/drinks/favoriteDrinks/${testUserId}`);
    
    expect(res.status).to.equal(200);
    expect(res.body).to.be.an('array');
    
    // If your endpoint returns drink objects, you can check that they have expected properties.
    //   Favorite Drinks Endpoints
    // {
    //     _id: 'd61848d5-7320-4c4d-b0d8-a2686646cd0f',
    //     drinkID: 101,
    //     name: 'Pink Squirrel',
    //     description: 'The Pink Squirrel is a classic cocktail that originated in the mid-20th century, known for its distinctive pink hue and creamy, nutty flavor.',
    //     ingredients: [ '¾ oz. crème de noyaux', '¾ oz. white crème de cacao', 'cream' ],
    //     averageRating: 0,
    //     barServed: '011101',
    //     category: [ 'Cocktail', 'Other' ],
    //     calories: 290
    // }
    if (res.body.length > 0) {
      const drink = res.body[0];
      expect(drink).to.have.property("drinkID");
      expect(drink).to.have.property("name");
      expect(drink).to.have.property("description");
      expect(drink).to.have.property("ingredients");
      expect(drink).to.have.property("averageRating");
      expect(drink).to.have.property("barServed");
      expect(drink).to.have.property("category");
      expect(drink).to.have.property("calories");
      expect(drink).to.have.property("_id");
    }
  });

  it('should return an empty array when no favorite drinks exist', async function () {
    // Update the test user to have an empty favorites array.
    await User.findByIdAndUpdate(testUserId, { favoriteDrinks: [] });
    
    const res = await request(app).get(`/api/drinks/favoriteDrinks/${testUserId}`);
    
    expect(res.status).to.equal(200);
    expect(res.body).to.be.an('array').that.is.empty;
  });
  it('should toggle favorite drink correctly', async function () {
    // First, ensure the test user's favorites are empty.
    await User.findByIdAndUpdate(testUserId, { favoriteDrinks: [] });
    
    // 1. Toggle favorite to add the drink (with drinkId 101).
    let res = await request(app)
      .post('/api/drinks/toggleFavoriteDrink')
      .send({ userId: testUserId, drinkId: 101 });
    expect(res.status).to.equal(200);
    
    // 2. Verify that the drink has been added.
    res = await request(app).get(`/api/drinks/favoriteDrinks/${testUserId}`);
    expect(res.status).to.equal(200);
    expect(res.body).to.be.an('array');
    // Check that at least one drink has drinkID 101.
    const found = res.body.some(drink => drink.drinkID === 101);
    expect(found).to.be.true;
    
    // 3. Toggle favorite again to remove the drink.
    res = await request(app)
      .post('/api/drinks/toggleFavoriteDrink')
      .send({ userId: testUserId, drinkId: 101 });
    expect(res.status).to.equal(200);
    
    // 4. Verify that the favorite drinks array is now empty.
    res = await request(app).get(`/api/drinks/favoriteDrinks/${testUserId}`);
    expect(res.status).to.equal(200);
    expect(res.body).to.be.an('array').that.is.empty;
  });
});