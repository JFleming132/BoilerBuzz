const mongoose = require('mongoose');

const userSchema = new mongoose.Schema({
    email: {
        type: String,
        required: true,
        unique: true,
        match: [
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
        type: String, // URL to the profile picture
        default: "https://example.com/default-profile.png"
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
    ratingCount: {
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
        objectId: {
            type: String,
            required: true
        },
        rating: {
            type: Number,
            required: true,
            min: 0,
            max: 5
        }
    }],
    friends: [{
        type: String
    }],
    isAdmin: {
        type: Boolean,
        default: false
    },
    isBanned: {
        type: Boolean,
        default: false
    },
    isIdentified: {
      type: Boolean,
      default: false
    },
    spendLimit: {
        type: Number,
        default: 200.0
    },
    currentSpent: {
        type: Number,
        default: 0.0
    },
    expenses: [{
        name: String,
        amount: Number,
        date: { type: Date, default: Date.now }
    }],
    notificationPreferences: {
        drinkSpecials: {
            type: Boolean,
            default: false
        },
        eventUpdates: {
            type: Boolean,
            default: false
        },
        eventReminders: {
            type: Boolean,
            default: false
        },
        announcements: {
            type: Boolean,
            default: false
        },
        locationBasedOffers: {
            type: Boolean,
            default: false
        },
        friendPosting: {
            type: Map,
            of: Boolean,
            default: {}
        }
    }
});

const User = mongoose.model('User', userSchema);

module.exports = User;
