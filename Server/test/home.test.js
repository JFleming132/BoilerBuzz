//
//  home.test.js
//  BoilerBuzz
//
//  Created by Joseph Fleming on 4/24/25.
//

//TODO: Write this entire file
// in before,
//     create a user
//     have that user create an event
//
// in after,
//    delete the user and his event
//
// Test that the new event shows up when fetching events
// Test that a user can successfully RSVP and it reflects the change in the event and the user
// Test that a user can successfully un-RSVP and it reflects the change in the event and the user. Maybe combine this test and the prev one?
// Test that a user can update the event information
// Test that fetching the events via the user-filter endpoint correctly fetches only events from that user
// Test that a user can delete events
//
//  home.test.js
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
import homeRouter from '../Routes/home.js';

const app = express();
app.use(express.json());
app.use('/api/home', homeRouter);

function getYesterday() {
    const today = new Date();
    today.setDate(today.getDate() - 1);
    console.log("yesterdays timestamp: " + today.getTime())
    return today.getTime()
}

function getTomorrow() {
    const today = new Date();
    today.setDate(today.getDate() + 1);
    console.log("tomorrows timestamp: " + today.getTime())
    return today.getTime()
}

describe('Home Endpoints', function () {
    var userId,
        blockedUserId,
        randomUserId,
        tr,
        tomorrowEventId,
        yesterdayEventId,
        tomorrowBlockedEventId,
        yesterdayBlockedEventId,
        deletedEventId,
        newEventId,
        rsvpEventId,
        tomorrowDate,
        yesterdayDate,
        authoredEventId;
    
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
        
        yesterdayDate = getYesterday();
        if (isNaN(yesterdayDate)) {
            return res.status(400).json({ message: 'Invalid date format' });
        }
        
        tomorrowDate = getTomorrow();
        if(isNaN(tomorrowDate)) {
            return res.status(400).json({message: 'Invalid date format' })
        }

        //set up 6 test events
        //RSVP event
        //Tomorrow event
        //yesterday event
        //blocked tomorrow event
        //blocked yesterday event
        //Deleted event
        const RSVPEvent = new Event({
            title: "RSVPTest",
            author: randomUserId,
            rsvpCount: 1,
            promoted: false,
            description: "test event",
            location: "NA",
            capacity: 20,
            is21Plus: false,
            date: tomorrowDate,
            imageUrl: "",
            authorUsername: "unblockedUserTest"
        });
        var tr = await RSVPEvent.save()
        if (tr) {
            rsvpEventId = tr._id
        }
        
        const tomorrowEvent = new Event({
            title: "tomorrowEvent",
            author: randomUserId,
            rsvpCount: 0,
            promoted: false,
            description: "test event",
            location: "NA",
            capacity: 20,
            is21Plus: false,
            date: tomorrowDate,
            imageUrl: "",
            authorUsername: "unblockedUserTest"
        });
        tr = await tomorrowEvent.save()
        if (tr) {
            tomorrowEventId = tr._id
        }
        
        const yesterdayEvent = new Event({
            title: "yesterdayTest",
            author: randomUserId,
            rsvpCount: 0,
            promoted: false,
            description: "test event",
            location: "NA",
            capacity: 20,
            is21Plus: false,
            date: yesterdayDate,
            imageUrl: "",
            authorUsername: "unblockedUserTest"
        });
        var tr = await yesterdayEvent.save()
        if (tr) {
            console.log(yesterdayEvent.date)
            yesterdayEventId = tr._id
        }
        
        const tomorrowBlockedEvent = new Event({
            title: "tomorrowBlockedTest",
            author: blockedUser._id.toString(),
            rsvpCount: 0,
            promoted: false,
            description: "test event",
            location: "NA",
            capacity: 20,
            is21Plus: false,
            date: tomorrowDate,
            imageUrl: "",
            authorUsername: "blockedUser"
        });
        var tr = await tomorrowBlockedEvent.save()
        if (tr) {
            tomorrowBlockedEventId = tr._id
        }
        
        const yesterdayBlockedEvent = new Event({
            title: "yesterdayBlockedTest",
            author: blockedUser._id.toString(),
            rsvpCount: 0,
            promoted: false,
            description: "test event",
            location: "NA",
            capacity: 20,
            is21Plus: false,
            date: yesterdayDate,
            imageUrl: "",
            authorUsername: "blockedUser"
        });
        var tr = await yesterdayBlockedEvent.save()
        if (tr) {
            yesterdayBlockedEventId = tr._id
        }
        
        // Create primary test user.
        const primaryUser = new User({
            email: "calendartest1@example.com",
            username: "primaryuser",
            password: "password",
            friends: [], // Initially no friends.
            blockedUserIDs: [blockedUserId],
            rsvpEvents: [rsvpEventId]
        });
        await primaryUser.save();
        userId = primaryUser._id.toString();
        const userObjId = primaryUser._id;
        
        // Create an event to be deleted as part of a test case
        const deletedEvent = new Event({
            title: "deletedEvent",
            author: randomUserId,
            rsvpCount: 0,
            promoted: false,
            description: "test event",
            location: "NA",
            capacity: 20,
            is21Plus: false,
            date: tomorrowDate,
            imageUrl: "",
            authorUsername: "unblockedUserTest"
        })
        var tr = await deletedEvent.save();
        
        if (tr) {
            deletedEventId = tr._id
        }
         
        // Create an event whose author is primaryUser
        const authoredEvent = new Event({
            title: "authoredEvent",
            author: userObjId,
            rsvpCount: 0,
            promoted: false,
            description: "test event",
            location: "NA",
            capacity: 20,
            is21Plus: false,
            date: tomorrowDate,
            imageUrl: "",
            authorUsername: "primaryUser"
        })
        var tr = await authoredEvent.save();
        
        if (tr) {
            authoredEventId = tr._id
        }
    });

    // Clean up after tests.
         
    after(async function () {
        this.timeout(20000); // 20 seconds
        await User.deleteMany({ email: { $in: ["calendartest1@example.com", "calendartest2@example.com", "calendartest3@example.com"] } });
        await Event.deleteMany({ _id: { $in: [
            yesterdayEventId, tomorrowEventId, yesterdayBlockedEventId, tomorrowBlockedEventId, deletedEventId, newEventId, rsvpEventId
        ]}})
        await mongoose.connection.close();
    });

    // Tests
    
    it("should get events without specifying a current user, thus including blocked authors", async function () {
        
        const res = await request(app)
            .get('/api/home/events')
        const mappedEventIDs = res.body.map((event) => event._id);
        expect(mappedEventIDs).to.include(tomorrowEventId.toString())
        expect(mappedEventIDs).to.include(tomorrowBlockedEventId.toString())
        expect(mappedEventIDs).to.not.include(yesterdayEventId.toString())
        expect(mappedEventIDs).to.not.include(yesterdayBlockedEventId.toString())
         
    });
    
    it('should get events and make sure only the correct events are fetched', async function () {
        const res = await request(app)
            .get('/api/home/events')
            .query({currentUserID: userId.toString()})
        //console.log(res.body)
        const mappedEventIDs = res.body.map((event) => event._id);
        expect(res.status).to.equal(200)
        expect(mappedEventIDs).to.include(tomorrowEventId.toString())
        expect(mappedEventIDs).to.not.include(tomorrowBlockedEventId.toString())
        expect(mappedEventIDs).to.not.include(yesterdayEventId.toString())
        expect(mappedEventIDs).to.not.include(yesterdayBlockedEventId.toString())
    });

    it('should create a new event', async function () {
        const createdEventRequest = {
            title: "createdEvent",
            author: userId,
            rsvpCount: 0,
            promoted: false,
            description: "new created event",
            location: "NA",
            capacity: 20,
            is21Plus: false,
            date: tomorrowDate,
            imageUrl: "",
            authorUsername: "primaryuser"
        }
        const res = await request(app)
            .post('/api/home/events')
            .send(createdEventRequest)
        console.log(res.body)
        newEventId = res.body._id
        expect(res.status).to.equal(201)
        const createdEvent = await Event.findById(newEventId)
        expect(createdEvent).to.not.be.null;
    });
  
    it('should delete an event that already exists', async function () {
        const res = await request(app)
            .delete('/api/home/delEvents/' + deletedEventId.toString())
        console.log(res.body)
        const fetchedEvent = await Event.findById(deletedEventId)
        expect(res.status).to.equal(200)
        expect(fetchedEvent).to.be.null;
    });
       
    it('should update an event', async function () {
        var updatedEvent = {
            title: "tomorrowEvent",
            author: "unblockedUserTest",
            rsvpCount: 0,
            promoted: true,
            description: "updated test event",
            location: "NA",
            capacity: 5,
            is21Plus: true,
            date: tomorrowDate,
            imageUrl: "",
            authorUsername: "unblockedUserTest"
        }
        const res = await request(app)
            .put('/api/home/events/' + tomorrowEventId.toString())
            .send(updatedEvent)
        expect(res.status).to.equal(200)
        const fetchedEvent = await Event.findById(tomorrowEventId)
        expect(fetchedEvent.description).to.equal(updatedEvent.description)
        expect(fetchedEvent.is21Plus).to.equal(updatedEvent.is21Plus)
        expect(fetchedEvent.promoted).to.equal(updatedEvent.promoted)
        expect(fetchedEvent.capacity).to.equal(updatedEvent.capacity)
    });
    
    it('should RSVP to an event', async function () {
        const httpbody = {
            userId: userId.toString(),
            eventId: tomorrowEventId.toString()
        }
        const res = await request(app)
            .post('/api/home/rsvp')
            .send(httpbody)
        expect(res.status).to.equal(200)
        const fetchedUser = await User.findById(userId)
        const mappedEventIDs = fetchedUser.rsvpEvents.map((event) => event.toString())
        expect(mappedEventIDs).to.include(tomorrowEventId.toString())
    });
    
    it('should un-RSVP from an event', async function () {
        const httpbody = {
            userId: userId.toString(),
            eventId: rsvpEventId.toString()
        }
        const res = await request(app)
            .post('/api/home/unrsvp')
            .send(httpbody)
        expect(res.status).to.equal(200)
        const fetchedUser = await User.findById(userId)
        const mappedEventIDs = fetchedUser.rsvpEvents.map((event) => event.toString())
        expect(mappedEventIDs).to.not.include(rsvpEventId.toString())
    })
    
    it('should get all events by a user\'s id', async function () {
        const res = await request(app)
            .get('/api/home/events/byUser/' + userId)
        expect(res.status).to.equal(200)
        const mappedEventIDs = res.body.map((event) => event._id)
        expect(mappedEventIDs).to.include(authoredEventId.toString())
    });
});

