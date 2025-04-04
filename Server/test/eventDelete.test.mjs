import { expect } from 'chai';
import request from 'supertest';
import express from 'express';
import mongoose from 'mongoose';
import homeRoutes from '../Routes/home.js'; // Adjust the path if needed

// Create an Express app and mount the homeRoutes on /api/home.
const app = express();
app.use(express.json());
app.use('/api/home', homeRoutes);

describe('DELETE events endpoints', function () {
  this.timeout(10000);
  let createdEventId;

  // Before tests, connect to the test database and create an event.
  before(async function () {
    await mongoose.connect('mongodb+srv://skonger6:Meiners1@cluster0.ytchv.mongodb.net/Boiler_Buzz?retryWrites=true&w=majority&appName=Cluster0');
    
    // Create a dummy event using the POST endpoint.
    const newEvent = {
      title: "Test Event",
      author: "67c208c071b197bb4b40fd84", // Use a valid test user id.
      rsvpCount: 0,
      promoted: false,
      description: "Test Description",
      location: "Test Location",
      capacity: 100,
      is21Plus: false,
      date: Date.now(),
      imageUrl: "",
      authorUsername: "testuser"
    };

    const res = await request(app)
      .post('/api/home/events')
      .send(newEvent)
      .expect(201);
    
    createdEventId = res.body._id;
    expect(createdEventId).to.be.a('string');
  });

  it('should delete an existing event', async function () {
    const res = await request(app)
      .delete(`/api/home/delEvents/${createdEventId}`)
      .expect(200);
    expect(res.body).to.have.property('message', 'Event deleted successfully');
  });

  it('should return 404 for a non-existent event', async function () {
    const nonExistentId = new mongoose.Types.ObjectId().toString();
    const res = await request(app)
      .delete(`/api/home/delEvents/${nonExistentId}`)
      .expect(404);
    expect(res.body).to.have.property('message', 'Event not found');
  });


  // Clean up after tests.
  after(async function () {
    await mongoose.connection.close();
  });
});
