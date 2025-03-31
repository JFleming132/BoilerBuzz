const mongoose = require('mongoose');

const eventReportSchema = new mongoose.Schema({
  eventId: { type: mongoose.Schema.Types.ObjectId, ref: 'Event', required: true },
  reporterId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  reporterFirstName: { type: String, required: true },
  reporterLastName: { type: String, required: true },
  reason: { type: String, required: true },
  additionalInfo: { type: String },
  createdAt: { type: Date, default: Date.now }
});

module.exports = mongoose.model('EventReport', eventReportSchema);