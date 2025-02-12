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
const authRoutes = require('./Routes/auth')

const app = express();
const port = 3000;

const cors = require('cors');
app.use(cors());

// our middleware
app.use(express.json());

// MongoDB connection
//mongoose.connect('mongodb://localhost:27017/userdb', { useNewUrlParser: true, useUnifiedTopology: true });

// Mongo User Model
//const User = mongoose.model('User', {
//    username: String,
//    password: String
//});

app.use('/api/auth', authRoutes);

app.listen(port, () => {
    console.log(`Server running on http://localhost:${port}`);
});

