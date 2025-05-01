// eventReport.test.mjs

import { expect } from 'chai';
import request from 'supertest';
import express from 'express';
import mongoose from 'mongoose';
import reportRoutes from '../Routes/report.js'; // Adjust path if needed

// Create an Express app and mount the report routes on /api/report.
const app = express();
app.use(express.json());
app.use('/api/report', reportRoutes);

// We'll use a dummy eventId and reporterId using mongoose ObjectIds.
const dummyEventId = new mongoose.Types.ObjectId().toString();
const dummyReporterId = new mongoose.Types.ObjectId().toString();

describe('Event Report Endpoints', function () {
  this.timeout(10000);

  // Connect to test database before tests.
  before(async function () {
    await mongoose.connect('mongodb+srv://skonger6:Meiners1@cluster0.ytchv.mongodb.net/Boiler_Buzz?retryWrites=true&w=majority&appName=Cluster0');
  });

  // Clean up the EventReport collection after tests.
  after(async function () {
    // Assuming EventReport is your model for event reports.
    const EventReport = mongoose.model('EventReport');
    await EventReport.deleteMany({ eventId: dummyEventId });
    await mongoose.connection.close();
  });

  it('should submit a new event report successfully', async function () {
    const reportData = {
      eventId: dummyEventId,
      reporterId: dummyReporterId,
      reporterFirstName: "Test",
      reporterLastName: "User",
      reason: "Inappropriate content",
      additionalInfo: "This event violates our guidelines."
    };

    const res = await request(app)
      .post('/api/report/submit')
      .send(reportData)
      .expect(201);

    expect(res.body).to.have.property('message', 'Report submitted successfully');
    expect(res.body).to.have.property('report');
    expect(res.body.report).to.have.property('eventId', dummyEventId);
    expect(res.body.report).to.have.property('reporterFirstName', 'Test');
  });

  it('should fetch event reports for a given event', async function () {
    // First, submit a new report to ensure there is at least one.
    const reportData = {
      eventId: dummyEventId,
      reporterId: dummyReporterId,
      reporterFirstName: "Another",
      reporterLastName: "Tester",
      reason: "Spam",
      additionalInfo: "Unwanted event."
    };

    await request(app)
      .post('/api/report/submit')
      .send(reportData)
      .expect(201);

    // Now, fetch the reports for dummyEventId.
    const res = await request(app)
      .get(`/api/report/${dummyEventId}`)
      .expect(200);

    expect(res.body).to.be.an('array');
    expect(res.body.length).to.be.greaterThan(0);
    // Optionally, verify that at least one report has the expected reporter info.
    const report = res.body.find(r => r.reporterFirstName === "Another");
    expect(report).to.exist;
    expect(report).to.have.property('reason', 'Spam');
  });

  it('should return 400 when required fields are missing', async function () {
    const incompleteData = {
      // Missing eventId, reporterId, reporterFirstName, reporterLastName, and reason.
      additionalInfo: "Incomplete data test"
    };

    const res = await request(app)
      .post('/api/report/submit')
      .send(incompleteData)
      .expect(400);
      
    expect(res.body).to.have.property('message', 'Missing required fields');
  });
});
