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
const eventRoutes = require('./Routes/eventRoutes');
const messagesRoutes = require('./Routes/messages')
const drinkSpecialsRoutes = require('./Routes/drinkSpecials');
const campusStatusRoutes = require('./Routes/campusStatus');

const cron = require('node-cron');
const User = require('./Models/User');
const { exec } = require('child_process');
const cors = require('cors');


const app = express();
const port = 3000;

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
    //console.log("Running aggregate.js...");

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


const CampusStatus = require('./Models/CampusStatus');

// Daily campus status update at midnight
cron.schedule('0 0 * * *', async () => {
  console.log('Running campus status update...');
  
  try {
    // Get all users
    const users = await User.find({});
    
    // Process in batches of 100
    for (let i = 0; i < users.length; i += 100) {
      const batch = users.slice(i, i + 100);
      
      await Promise.all(batch.map(async (user) => {
        // Get most recent location within last 24h
        const recentLocation = await mongoose.connection.db.collection('user_locations')
          .findOne(
            { userId: user._id, lastUpdate: { $gte: new Date(Date.now() - 24 * 60 * 60 * 1000) } },
            { sort: { lastUpdate: -1 } }
          );

        const isOnCampus = recentLocation ? 
          isWithinCampusGeoFence(recentLocation) : false;

        await CampusStatus.updateOne(
          { userId: user._id },
          { 
            $set: { 
              isOnCampus,
              lastChecked: new Date() 
            }
          },
          { upsert: true }
        );
      }));
    }
    
    console.log('Campus status update completed');
  } catch (err) {
    console.error('Campus status update failed:', err);
  }
});

// Geo-fence helper function
function isWithinCampusGeoFence(location) {
  // Purdue University coordinates
  const campusCenter = { lat: 40.4237, lng: -86.9232 };
  const radius = 8000; // meters
  
  // Haversine formula
  const R = 6371000;
  const dLat = (location.latitude - campusCenter.lat) * Math.PI/180;
  const dLon = (location.longitude - campusCenter.lng) * Math.PI/180;
  const a = Math.sin(dLat/2) * Math.sin(dLat/2) +
            Math.cos(campusCenter.lat * Math.PI/180) *
            Math.cos(location.latitude * Math.PI/180) *
            Math.sin(dLon/2) * Math.sin(dLon/2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a));
  const distance = R * c;
  
  return distance <= radius;
}


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
app.use('/api/pin', eventRoutes);
app.use('/api/messages', messagesRoutes);
app.use('/api/users', campusStatusRoutes);

// Start the server
const http = require('http');
const { Server } = require('socket.io');
const server = http.createServer(app);
const io = new Server(server, {
    cors: { origin: '*' }
});

app.use('/api/drinkspecials', drinkSpecialsRoutes(io)); // Pass the Socket.IO instance to the drinkSpecials routes

// Import and start the event watcher (listening for new events)
const { startEventWatcher } = require('./eventWatcher');
startEventWatcher(io);

// Start the HTTP server
server.listen(port, () => {
    console.log(`Server running on http://localhost:${port}`);
});
