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
    let userId, rsvpEventId, promotedEventId, bothEventId, neitherEventId, blockedPromotedEventId;

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
        
        //TODO: Add some dummy events to calendar:
        //one promoted
        //one rsvpd
        //one both
        //one neither
        //one promoted but authored by a blocked user
        
        // Create primary test user.
        const primaryUser = new User({
            email: "calendartest1@example.com",
            username: "primaryuser",
            password: "password",
            friends: [] // Initially no friends.
            blockedUserIDs: [blockedUser]
            //TODO: Add some RSVP events
            //TODO: Add a blocked user
        });
        await primaryUser.save();
        userId = primaryUser._id.toString();
    });

    // Clean up after tests.
    after(async function () {
        this.timeout(20000); // 20 seconds
        await User.deleteMany({ email: { $in: ["calendartest1@example.com", "calendartest2@example.com"] } });
        //Delete test events
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
