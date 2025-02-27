//
//  Drink.js
//  BoilerBuzz
//
//  Created by Matt Zlatniski on 2/25/25.
//

const mongoose = require('mongoose');

const drinkSchema = new mongoose.Schema({
    _id: {
        type: String,
        required: true
    },
    drinkID: {
        type: Number,
        required: true
    },
    name: {
        type: String,
        required: true
    },
    description: {
        type: String
    },
    ingredients: {
        type: [String]
    },
    averageRating: {
        type: Number,
        default: 0
    },
    ratingCount: {
        type: Number,
        default: 0
    },
    ratings: [
        {
            userId: { type: String, required: true },
            rating: { type: Number, required: true, min: 0, max: 5 },
        }
    ],
    barServed: {
        type: String
    },
    category: {
        type: [String]
    },
    calories: {
        type: Number
    }
});

const Drink = mongoose.model('Drink', drinkSchema);
module.exports = Drink;
