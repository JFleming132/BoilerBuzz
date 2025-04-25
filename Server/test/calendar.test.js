//
//  calendar.test.js
//  BoilerBuzz
//
//  Created by Joseph Fleming on 4/24/25.
//

import { expect } from 'chai';
import request from 'supertest';
import express from 'express';
import mongoose from 'mongoose';
import User from '../Models/User.js';
import Event from '../Models/Event.js';
const app = express();
app.use(express.json());
app.use('/api/auth', authRouter);

describe('Calendar Endpoints', function () {
    var userId, rsvpEventId, promotedEventId, bothEventId, neitherEventId, blockedPromotedEventId, tr;

    // Before tests, connect to a test database and create two test users.
    before(async function () {
        this.timeout(20000); // 20 seconds
        await mongoose.connect('mongodb+srv://skonger6:Meiners1@cluster0.ytchv.mongodb.net/Boiler_Buzz?retryWrites=true&w=majority&appName=Cluster0');
        
        
        // Clean up any previous test users.
        await User.deleteMany({ email: { $in: ["friendtest1@example.com", "friendtest2@example.com"] } });
        
        const blockedUser = new User({
            email: "calendartest2@example.com"
            username: "blockeduser"
            password: "password"
        })
        
        const formattedDate = new Date().getTime();
        if (isNaN(formattedDate)) {
            return res.status(400).json({ message: 'Invalid date format' });
        }
        
        //set up 5 test events
        const newPromotedEvent = new Event({
            "promotedTest",
            "unblockedUserTest",
            0,
            true,
            "test event",
            "NA",
            20,
            false, 
            date: formattedDate,
            imageUrl: "",
            "unblockedUserTest"
        });
        tr = await newPromotedEvent.save()
        if (tr) {
            promotedEventId = tr._id
        }
        
        const newRSVPEvent = new Event({
            "RSVPTest",
            "unblockedUserTest",
            0,
            false,
            "test event",
            "NA",
            20,
            false,
            date: formattedDate,
            imageUrl: "",
            "unblockedUserTest"
        });
        var tr = await newRSVPEvent.save()
        if (tr) {
            rsvpEventId = tr._id
        }
        
        const newBothEvent = new Event({
            "promotedTest",
            "unblockedUserTest",
            0,
            true,
            "test event",
            "NA",
            20,
            false,
            date: formattedDate,
            imageUrl: "",
            "unblockedUserTest"
        });
        var tr = await newBothEvent.save()
        if (tr) {
            bothEventId = tr._id
        }
        
        const newNeitherEvent = new Event({
            "promotedTest",
            "unblockedUserTest",
            0,
            false,
            "test event",
            "NA",
            20,
            false,
            date: formattedDate,
            imageUrl: "",
            "unblockedUserTest"
        });
        var tr = await newNeitherEvent.save()
        if (tr) {
            neitherEventId = tr._id
        }
        
        const newBlockedPromotedEvent = new Event({
            "promotedTest",
            blockedUser,
            0,
            true,
            "test event",
            "NA",
            20,
            false,
            date: formattedDate,
            imageUrl: "",
            "blockedUser"
        });
        var tr = await newBlockedPromotedEvent.save()
        if (tr) {
            blockedPromotedEventId = tr._id
        }
        
        // Create primary test user.
        const primaryUser = new User({
            email: "calendartest1@example.com",
            username: "primaryuser",
            password: "password",
            friends: [] // Initially no friends.
            blockedUserIDs: [blockedUser]
            rsvpEvents = [rsvpEventId, bothEventId]
        });
        await primaryUser.save();
        userId = primaryUser._id.toString();
    });

    // Clean up after tests.
    after(async function () {
        this.timeout(20000); // 20 seconds
        await User.deleteMany({ email: { $in: ["calendartest1@example.com", "calendartest2@example.com"] } });
        await Event.deleteMany({ _id: { $in: [promotedEventId, rsvpEventId, bothEventId, neitherEventId, blockedPromotedEventId]}})
        await mongoose.connection.close();
    });

    it('should return false if the RSVP event is not in retrieved list', async function () {
        const res = await request(app)
            .get('/api/calendar/events?userId=${currentUserId}');
        expect(res.status).to.equal(200)
        expect(res).to.deep.include({id: rsvpEventId})
    });

    it('should return false if the Promoted event is not in retrieved list', async function () {
        const res = await request(app)
            .get('/api/calendar/events?userId=${currentUserId}');
            //expect response to contain promoted event
        expect(res.status).to.equal(200)
        expect(res.body).to.deep.include({id: promotedEventId})
    });
  
    it('should return false if the RSVPd and Promoted event is not in retrieved list', async function () {
       const res = await request(app)
           .get('/api/calendar/events?userId=${currentUserId}');
           //expect response to contain both event
        expect(res.status).to.equal(200)
        expect(res.body).to.deep.include({id: bothEventId})
    });
    
    it('should return false if the event that is not promoted nor RSVPd is in the retrieved list'), async function () {
        const res = await request(app)
            .get('/api/calendar/events?userId=${currentUserId}');
        expect(res.status).to.equal(200)
        expect(res.body).to.not.deep.include({id: neitherEventId})
    }
});
