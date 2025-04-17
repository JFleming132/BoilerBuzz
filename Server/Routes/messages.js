//
//  messages.js
//  BoilerBuzz backend routes for conversations and messages
//

const express = require('express');
const router = express.Router();
const mongoose = require('mongoose');

const Conversation = require('../Models/Conversation');
const Messages = require('../Models/Messages');

// GET /api/getConversations?userId={userId}
router.get('/getConversations', async (req, res) => {
  try {
    const userId = req.query.userId;
    if (!userId) return res.status(400).json({ error: 'userId query required' });

    const convos = await Conversation.find({
      $or: [{ initiator: userId }, { recipient: userId }]
    })
    .populate('initiator', 'username profilePicture')
    .populate('recipient', 'username profilePicture')
    .populate({
      path: 'messages',
      select: 'text sentAt',
      options: { sort: { sentAt: 1 } }
    })
    .sort('-updatedAt');

    const result = convos.map(c => {
      const other = c.initiator._id.toString() === userId
        ? c.recipient
        : c.initiator;

      // grab only the final message text
      const lastMsgObj = c.messages[c.messages.length - 1];
      const lastText = lastMsgObj ? lastMsgObj.text : null;

      console.log(lastText)

      return {
        id: c._id.toString(),
        otherUser: {
          id: other._id.toString(),
          username: other.username,
          profilePicture: other.profilePicture
        },
        lastMessage: lastText
      };
    });

    res.json(result);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Server error fetching conversations' });
  }
});


// Create a new conversation (initial message request)
// POST /api/conversations
// Body: { initiator, recipient }
router.post('/conversations', async (req, res) => {
  try {
    const { initiator, recipient } = req.body;
    if (!initiator || !recipient) {
      return res.status(400).json({ error: 'initiator and recipient required' });
    }

    // Prevent duplicates
    let convo = await Conversation.findOne({ initiator, recipient })
      || await Conversation.findOne({ initiator: recipient, recipient: initiator });
    if (convo) {
      return res.status(200).json(convo);
    }

    convo = new Conversation({ initiator, recipient, status: 'pending' });
    await convo.save();
    res.status(201).json(convo);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Server error creating conversation' });
  }
});

// Update conversation status (accept/decline)
// PATCH /api/conversations/:id/status
// Body: { status: 'accepted' | 'declined' }
router.patch('/conversations/:id/status', async (req, res) => {
  try {
    const convId = req.params.id;
    const { status } = req.body;
    if (!['pending', 'accepted', 'declined', 'blocked'].includes(status)) {
      return res.status(400).json({ error: 'Invalid status value' });
    }
    const convo = await Conversation.findByIdAndUpdate(
      convId,
      { status, acceptedAt: status === 'accepted' ? Date.now() : null, updatedAt: Date.now() },
      { new: true }
    );
    res.json(convo);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Server error updating conversation status' });
  }
});

// Get all messages for a conversation
// GET /api/conversations/:id/messages
router.get('/conversations/:id/messages', async (req, res) => {
  try {
    const convId = req.params.id;
    if (!mongoose.Types.ObjectId.isValid(convId)) {
      return res.status(400).json({ error: 'Invalid conversation id' });
    }
    const conversation = await Conversation.findById(convId).populate({
      path: 'messages',
      populate: { path: 'sender', select: 'username profilePicture' }
    });
    if (!conversation) {
      return res.status(404).json({ error: 'Conversation not found' });
    }
    res.json(conversation.messages);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Server error fetching messages' });
  }
});

// Send a new message in a conversation
// POST /api/conversations/:id/messages
// Body: { sender, text }
router.post('/conversations/:id/messages', async (req, res) => {
  try {
    const convId = req.params.id;
    const { sender, text } = req.body;
    if (!sender || !text) {
      return res.status(400).json({ error: 'sender and text required' });
    }
    const convo = await Conversation.findById(convId);
    if (!convo || convo.status !== 'accepted') {
      return res.status(400).json({ error: 'Conversation not available for messaging' });
    }
    const message = await Message.create({ conversation: convId, sender, text });
    convo.messages.push(message._id);
    convo.updatedAt = Date.now();
    await convo.save();
    res.status(201).json(message);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Server error sending message' });
  }
});

// Mark message as read
// PATCH /api/conversations/:convId/messages/:msgId/read
// Body: { userId }
router.patch('/conversations/:convId/messages/:msgId/read', async (req, res) => {
  try {
    const { convId, msgId } = req.params;
    const { userId } = req.body;
    const message = await Message.findById(msgId);
    if (!message) {
      return res.status(404).json({ error: 'Message not found' });
    }
    if (!message.readBy.includes(userId)) {
      message.readBy.push(userId);
      await message.save();
    }
    res.json(message);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Server error marking read' });
  }
});

module.exports = router;

