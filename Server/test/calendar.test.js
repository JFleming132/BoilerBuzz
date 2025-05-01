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
import calendarRouter from '../Routes/calendar.js';

const app = express();
app.use(express.json());
app.use('/api/calendar', calendarRouter);

describe('Calendar Endpoints', function () {
    var userId, blockedUserId, rsvpEventId, promotedEventId, bothEventId, neitherEventId, blockedPromotedEventId, tr, randomUserId;
    // Before tests, connect to a test database and create two test users.
    before(async function () {
        this.timeout(20000); // 20 seconds
        await mongoose.connect('mongodb+srv://skonger6:Meiners1@cluster0.ytchv.mongodb.net/Boiler_Buzz?retryWrites=true&w=majority&appName=Cluster0');
        
        // Clean up any previous test users.
        await User.deleteMany({ email: { $in: ["friendtest1@example.com", "friendtest2@example.com"] } });
        
        const blockedUser = new User({
            email: "calendartest2@example.com",
            username: "blockeduser",
            password: "password"
        });
        await blockedUser.save()
        blockedUserId = blockedUser._id.toString()
        
        const randomUser = new User({
            email: "calendartest3@example.com",
            username: "unblockedUserTest",
            password: "password"
        })
        await randomUser.save()
        randomUserId = randomUser._id.toString()
        
        const formattedDate = new Date().getTime();
        if (isNaN(formattedDate)) {
            return res.status(400).json({ message: 'Invalid date format' });
        }

        //set up 5 test events
        
        const newPromotedEvent = new Event({
            title: "promotedTest",
            author: randomUserId,
            rsvpCount: 0,
            promoted: true,
            description: "test event",
            location: "NA",
            capacity: 20,
            is21Plus: false,
            date: formattedDate,
            imageUrl: "",
            authorUsername: "unblockedUserTest"
        });
        tr = await newPromotedEvent.save()
        if (tr) {
            promotedEventId = tr._id
        }
        
        const newRSVPEvent = new Event({
            title: "RSVPTest",
            author: randomUserId,
            rsvpCount: 0,
            promoted: false,
            description: "test event",
            location: "NA",
            capacity: 20,
            is21Plus: false,
            date: formattedDate,
            imageUrl: "",
            authorUsername: "unblockedUserTest"
        });
        var tr = await newRSVPEvent.save()
        if (tr) {
            rsvpEventId = tr._id
        }
        
        const newBothEvent = new Event({
            title: "bothTest",
            author: randomUserId,
            rsvpCount: 0,
            promoted: true,
            description: "test event",
            location: "NA",
            capacity: 20,
            is21Plus: false,
            date: formattedDate,
            imageUrl: "",
            authorUsername: "unblockedUserTest"
        });
        var tr = await newBothEvent.save()
        if (tr) {
            bothEventId = tr._id
        }
        
        const newNeitherEvent = new Event({
            title: "neitherTest",
            author: randomUserId,
            rsvpCount: 0,
            promoted: false,
            description: "test event",
            location: "NA",
            capacity: 20,
            is21Plus: false,
            date: formattedDate,
            imageUrl: "",
            authorUsername: "unblockedUserTest"
        });
        var tr = await newNeitherEvent.save()
        if (tr) {
            neitherEventId = tr._id
        }
        
        const newBlockedPromotedEvent = new Event({
            title: "blockedPromotedTest",
            author: blockedUserId,
            rsvpCount: 0,
            promoted: true,
            description: "test event",
            location: "NA",
            capacity: 20,
            is21Plus: false,
            date: formattedDate,
            imageUrl: "",
            authorUsername: "blockedUser"
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
            friends: [], // Initially no friends.
            blockedUserIDs: [blockedUserId],
            rsvpEvents: [rsvpEventId, bothEventId]
        });
        await primaryUser.save();
        userId = primaryUser._id.toString();
        
    });

    // Clean up after tests.
         
    after(async function () {
        this.timeout(20000); // 20 seconds
        await User.deleteMany({ email: { $in: ["calendartest1@example.com", "calendartest2@example.com", "calendartest3@example.com"] } });
        await Event.deleteMany({ _id: { $in: [promotedEventId, rsvpEventId, bothEventId, neitherEventId, blockedPromotedEventId]}})
        await mongoose.connection.close();
    });

    // Tests
    
    it('should return false if the RSVP event is not in retrieved list', async function () {
        const res = await request(app)
        .get('/api/calendar/events')
        .query({currentUserID: userId});
        if (res.body.error) {
            console.log(res.body.err)
        }
        const eventIds = res.body.map(event => (event._id))
        expect(res.status).to.equal(200)
        expect(eventIds).to.include(rsvpEventId.toString())
    });

    it('should return false if the Promoted event is not in retrieved list', async function () {
        const res = await request(app)
        .get('/api/calendar/events')
        .query({currentUserID: userId});
        if (res.body.error) {
            console.log(res.body.err)
        }
        const eventIds = res.body.map(event => (event._id))
        expect(res.status).to.equal(200)
        expect(eventIds).to.include(promotedEventId.toString())
    });
  
    it('should return false if the RSVPd and Promoted event is not in retrieved list', async function () {
        const res = await request(app)
        .get('/api/calendar/events')
        .query({currentUserID: userId});
        if (res.body.error) {
            console.log(res.body.err)
        }
        const eventIds = res.body.map(event => (event._id))
        expect(res.status).to.equal(200)
        expect(eventIds).to.include(bothEventId.toString())
    });
    
    it('should return false if the event that is not promoted nor RSVPd is in the retrieved list', async function () {
        const res = await request(app)
        .get('/api/calendar/events')
        .query({currentUserID: userId});
        if (res.body.error) {
            console.log(res.body.err)
        }
        const eventIds = res.body.map(event => (event._id))
        expect(res.status).to.equal(200)
        expect(eventIds).to.not.include(neitherEventId.toString())
    });
    
    it('should return false if the event that is promoted, but made by a blocked user, is in the retrieved list', async function () {
        const res = await request(app)
        .get('/api/calendar/events')
        .query({currentUserID: userId});
        if (res.body.error) {
            console.log(res.body.err)
        }
        const eventIds = res.body.map(event => (event._id))
        expect(res.status).to.equal(200)
        expect(eventIds).to.not.include(blockedPromotedEventId.toString())
    });
});
