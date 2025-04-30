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
    const testDrinkId = new mongoose.Types.ObjectId();
    const testTriedDrinkId = new mongoose.Types.ObjectId();
    
    before(async function () {
        await mongoose.connect('mongodb+srv://skonger6:Meiners1@cluster0.ytchv.mongodb.net/Boiler_Buzz?retryWrites=true&w=majority&appName=Cluster0');

        // Create an untried test drink.
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
        
        // Create a tried test drink
        const testTriedDrink = new Drink({
            _id: testTriedDrinkId,
            drinkID: 101,
            name: "Tried Drink",
            description: "A test drink that the user has tried.",
            ingredients: ["Ingredient1", "Ingredient2"],
            averageRating: 0,
            ratingCount: 0,
            ratings: [],
            barServed: "Test Bar",
            category: ["Test Category"],
            calories: 100
        });
        await testTriedDrink.save()
        
        
        // Create a test user with one tried drink
        const testUser = new User({
            email: "drinktest@example.com",
            username: "drinktestuser",
            password: "password",
            spendLimit: 200.0,
            currentSpent: 0.0,
            expenses: [],
            favoriteDrinks: [],
            triedDrinks: [{objectId: testTriedDrink._id.toString(), rating: 0}]
        });
        await testUser.save();
        testUserId = testUser._id.toString();
    });

    after(async function () {
    // Clean up: delete only the test user and test drink.
        await User.deleteOne({ _id: testUserId });
        await Drink.deleteOne({ _id: testDrinkId });
        await Drink.deleteOne({ _id: testTriedDrinkId })
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
        expect(user.triedDrinks.length).to.equal(2);
        const mappedDrinkIDs = user.triedDrinks.map((drink) => drink.objectId)
        expect(mappedDrinkIDs).to.include(testDrinkId.toString())

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

        // Verify that the user's triedDrinks array is now empty (except the tried test drink).
        const user = await User.findById(testUserId);
        expect(user.triedDrinks).to.have.lengthOf(1);

        // Verify that the test drink's ratings array is empty.
        const drink = await Drink.findById(testDrinkId);
        expect(drink.ratings).to.have.lengthOf(0);
        expect(drink.averageRating).to.equal(0);
    });
    
    it("should check if a tried drink has been tried", async function () {
        const res = await request(app)
            .get('/api/drinks/isDrinkTried')
            .query({userId: testUserId, drinkId: testTriedDrinkId.toString()})
        expect(res.status).to.equal(200);
        expect(res.body.isDrinkTried).to.equal(true);
    });
    
    it("should check if an untried drink has not been tried", async function () {
        const res = await request(app)
            .get('/api/drinks/isDrinkTried')
            .query({userId: testUserId, drinkId: testDrinkId.toString()})
        expect(res.status).to.equal(200);
        expect(res.body.isDrinkTried).to.equal(false)
    })
});
