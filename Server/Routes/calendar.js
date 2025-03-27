//
//  calendar.js
//  BoilerBuzz
//
//  Created by Joseph Fleming on 3/27/25.
//

const express = require('express');
const router = express.Router();
const mongoose = require('mongoose');
const { ObjectId } = require('mongodb');
const User = require('../Models/User');

//TODO: write GET backend call for calendar events
//Should fetch all of a user's RSVP'd events, all events that are promoted, then filter out those whose author's userIDs are in a user's blockedUserIDs list
//can probably write an aggregate function in mongoDB to do all that

module.exports = router;
