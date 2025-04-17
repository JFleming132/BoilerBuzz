// Conversation.js
const mongoose = require('mongoose');

const conversationSchema = new mongoose.Schema({
  initiator:   { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  recipient:   { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  status:      { type: String, enum: ['pending','accepted','declined'], default: 'pending' },
  messages:    [{ type: mongoose.Schema.Types.ObjectId, ref: 'Messages' }],
  updatedAt:   { type: Date, default: Date.now },
  acceptedAt:  { type: Date }
});

const Conversation = mongoose.model('Conversation', conversationSchema);
module.exports = Conversation;
