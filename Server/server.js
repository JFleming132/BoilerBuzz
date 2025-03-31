//
//  server.js
//  BoilerBuzz
//
//  Created by Matt Zlatniski on 2/12/25.
//
require('dotenv').config();
const express = require('express');
const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const authRoutes = require('./Routes/auth');
const profileRoutes = require('./Routes/profile');
const drinksRoutes = require('./Routes/drinks');
const friendsRoutes = require('./Routes/friends');
const spendingRoutes = require('./Routes/spending');
const locationRoutes = require('./Routes/location');
const homeRoutes = require('./Routes/home');
const ratingRoutes = require('./Routes/ratings');
const notificationRoutes = require('./Routes/notification');
const photoRoutes = require('./Routes/photo'); 
const reportRoutes = require('./Routes/report');
const blockedRoutes = require('./Routes/blocked');
const calendarRoutes = require('./Routes/calendar');

const cron = require('node-cron');
const User = require('./Models/User');
const { exec } = require('child_process');



const app = express();
const port = 3000;

const cors = require('cors');
app.use(cors());

//app.use(express.json());
app.use(express.json({ limit: "10mb" }));  // Increase JSON limit to 10MB
app.use(express.urlencoded({ limit: "10mb", extended: true }));  // Increase URL-encoded body limit


// MongoDB connection URI
const mongoURI = "mongodb+srv://skonger6:Meiners1@cluster0.ytchv.mongodb.net/Boiler_Buzz?retryWrites=true&w=majority&appName=Cluster0";

// Connect to MongoDB
mongoose.connect(mongoURI)
    .then(() => console.log("\nMongoDB connected successfully"))
    .catch(err => console.log("\nMongoDB connection error:", err));


// Schedule a cron job to run at midnight on the 1st of every month
cron.schedule('0 0 1 * *', async () => {
    try {
        console.log("Resetting currentSpent and clearing expenses for all users...");
        
        await User.updateMany({}, {
            $set: { currentSpent: 0, expenses: [] }  // Reset `currentSpent` and clear `expenses`
        });

        console.log("Successfully reset currentSpent and cleared expenses for all users.");
    } catch (error) {
        console.error("Error resetting currentSpent and clearing expenses:", error);
    }
});

// Schedule aggregate.js to run every minute
cron.schedule('* * * * *', () => {
    console.log("Running aggregate.js...");

    exec('node aggregate.js', (error, stdout, stderr) => {
        if (error) {
            console.error(`Error executing aggregate.js: ${error.message}`);
            return;
        }
        if (stderr) {
            console.error(`aggregate.js stderr: ${stderr}`);
            return;
        }
        console.log(`aggregate.js output:\n${stdout}`);
    });
})

app.use((req, res, next) => {
    console.log(`Incoming Request: ${req.method} ${req.url}`);
    next();
});


// Routes for authentication
app.use('/api/auth', authRoutes);
app.use('/api/profile', profileRoutes);
app.use('/api/drinks', drinksRoutes);
app.use('/api/friends', friendsRoutes);
app.use('/api/spending', spendingRoutes);
app.use('/api/location', locationRoutes);
app.use('/api/home', homeRoutes);
app.use('/api/ratings', ratingRoutes);
app.use('/api/notification', notificationRoutes);
app.use('/api/photo', photoRoutes);
app.use('/api/report', reportRoutes);
app.use('/api/blocked', blockedRoutes);
app.use('/api/calendar', calendarRoutes);

// Start the server
app.listen(port, () => {
    console.log(`Server running on http://localhost:${port}`);
});
