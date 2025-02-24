//
//  User.js
//  BoilerBuzz
//
//  Created by Matt Zlatniski on 2/12/25.
//
const mongoose = require('mongoose');

const userSchema = new mongoose.Schema({
    email: {
        type: String,
        required: true,  // email is required
        unique: true,    // email should be unique
        match: [         // regex pattern to validate email format
            /^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$/,
            'Please enter a valid email address'
        ],
    },
    username: {
        type: String,
        required: true,
        unique: true,
    },
    password: {
        type: String,
        required: true,
    },
    emailVerified: {
        type: Boolean,
        default: false
    },
    verificationToken: {
        type: String
    },
    // Profile info
    bio: {
        type: String,
        default: "No bio yet."
    },
    profilePicture: {
        type: String, // base64 Encoding of pfp
        default: ""
    },
    favoriteDrinks: [{
        type: String
    }], 
    pastEvents: [{
        type: String
    }], 
    rating: {
        type: Number,
        default: 0
    },

    status: {
        type: String,
        enum: ["user", "admin"],
        default: "user"
    },
    forgotPasswordToken: {
        type: String,
        default: null
    },
    triedDrinks: [{ 
          type: String
      }]
});


const User = mongoose.model('User', userSchema);

module.exports = User;
