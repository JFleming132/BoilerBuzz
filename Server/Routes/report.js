const express = require('express');
const router = express.Router();
const EventReport = require('../Models/EventReport');

// POST endpoint to submit a new event report
router.post('/submit', async (req, res) => {
  try {
    const { eventId, reporterId, reporterFirstName, reporterLastName, reason, additionalInfo } = req.body;
    
    // Validate required fields.
    if (!eventId || !reporterFirstName || !reporterLastName || !reason || !reporterId) {
      return res.status(400).json({ message: 'Missing required fields' });
    }
    
    const newReport = new EventReport({
      eventId,
      reporterId,
      reporterFirstName,
      reporterLastName,
      reason,
      additionalInfo
    });
    
    await newReport.save();
    
    res.status(201).json({ message: 'Report submitted successfully', report: newReport });
  } catch (error) {
    console.error("Error submitting report:", error);
    res.status(500).json({ message: "Error submitting report", error });
  }
});

// (Optional) GET endpoint to fetch reports for a given event
router.get('/:eventId', async (req, res) => {
  try {
    const { eventId } = req.params;
    const reports = await EventReport.find({ eventId });
    res.status(200).json(reports);
  } catch (error) {
    console.error("Error fetching reports:", error);
    res.status(500).json({ message: "Error fetching reports", error });
  }
});

module.exports = router;
