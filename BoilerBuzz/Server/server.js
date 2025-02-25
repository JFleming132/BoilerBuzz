//
//  server.js
//  BoilerBuzz
//
//  Created by Matt Zlatniski on 2/12/25.
//
const express = require('express');
const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const authRoutes = require('./Routes/auth');
const profileRoutes = require('./Routes/profile');
const drinksRoutes = require('./Routes/drinks');
const friendsRoutes = require('./Routes/friends');


const app = express();
const port = 3000;

const cors = require('cors');
app.use(cors());

// Middleware to parse incoming JSON requests
app.use(express.json());

// MongoDB connection URI
const mongoURI = "mongodb+srv://skonger6:Meiners1@cluster0.ytchv.mongodb.net/Boiler_Buzz?retryWrites=true&w=majority&appName=Cluster0";

// Connect to MongoDB
mongoose.connect(mongoURI)
    .then(() => console.log("\nMongoDB connected successfully"))
    .catch(err => console.log("\nMongoDB connection error:", err));


// Routes for authentication
app.use('/api/auth', authRoutes);
app.use('/api/profile', profileRoutes);
app.use('/api/drinks', drinksRoutes);
app.use('/api/friends', friendsRoutes);

// Start the server
app.listen(port, () => {
    console.log(`Server running on http://localhost:${port}`);
});




