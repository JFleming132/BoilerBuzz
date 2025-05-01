// models/DrinkSpecial.js
const mongoose = require('mongoose');

// Subdocument schema for structured offers
const OfferSchema = new mongoose.Schema({
  name:  { type: String, required: true },  // e.g. "Margarita"
  price: { type: Number, required: true }   // e.g. 3.00
});

const DrinkSpecialSchema = new mongoose.Schema({
  title:       { type: String, required: true },   // e.g. "$3 Margaritas"
  author:      { type: String, required: true },   // bar account ID
  barName:     { type: String, required: true },   // for display
  description: { type: String },                    // free-form details
  imageUrl:    { type: String },                    // optional image
  offers:      { type: [OfferSchema], default: [] },// array of offers with name & price
  createdAt:   { type: Number, default: Date.now }, // ms timestamp
  expiresAt:   { type: Number, required: true }     // ms timestamp when the special ends
});

module.exports = mongoose.model('DrinkSpecial', DrinkSpecialSchema);
