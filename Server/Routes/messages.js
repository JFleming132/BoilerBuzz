//
//  messages.js
//  BoilerBuzz backend routes for conversations and messages
//

const express = require('express');
const router = express.Router();
const mongoose = require('mongoose');

const Conversation = require('../Models/Conversation');
const Message = require('../Models/Messages');
const User = require('../Models/User')

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
      select: 'text sender sentAt',
      options: { sort: { sentAt: 1 } }
    })
    .sort('-updatedAt');

    const result = convos.map(c => {
      const other = c.initiator._id.toString() === userId
        ? c.recipient
        : c.initiator;

      const simpleMessages = c.messages.map(msg => ({
        id: msg._id.toString(),
        text: msg.text,
        sender: msg.sender.toString()
      }));

      const lastText = simpleMessages.length
        ? simpleMessages[simpleMessages.length - 1].text
        : null;

      return {
        id: c._id.toString(),
        initiatorId: c.initiator._id.toString(),   // ← ADDED initiator ID
        otherUser: {
          id: other._id.toString(),
          username: other.username,
          profilePicture: other.profilePicture
        },
        messages: simpleMessages,
        lastMessage: lastText,
        status: c.status
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

// GET /api/messages/conversations/:id/messages
router.get('/conversations/:id/messages', async (req, res) => {
  try {
    const convId = req.params.id;
    if (!mongoose.Types.ObjectId.isValid(convId)) {
      return res.status(400).json({ error: 'Invalid conversation id' });
    }

    // Load the conversation and populate its messages (sorted by sentAt)
    const conversation = await Conversation.findById(convId).populate({
      path: 'messages',
      select: 'text sender sentAt',
      options: { sort: { sentAt: 1 } }
    });

    if (!conversation) {
      return res.status(404).json({ error: 'Conversation not found' });
    }

    // Map to only text + sender string
    const simpleMessages = conversation.messages.map(msg => ({
      text: msg.text,
      sender: msg.sender.toString()
    }));

    res.json(simpleMessages);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Server error fetching messages' });
  }
});

// Post API endpoint for sendMessage
router.post("/conversations/:id/sendMessage", async(req, res) => {
  try {
    const convoId = req.params.id;
    const { messageText, sender, other } = req.body;

    if (!messageText || !sender || !other) {
      res.status(400).json({ error: 'Message text or one of the user ids were empty'});
    }

    const senderExists = await User.findById(sender);
    if (!senderExists) {
      return res.status(400).json({ error: 'sender user id is not valid' })
    }

    const otherExists = await User.findById(other);
    if (!otherExists) {
      return res.status(400).json({ error: 'recieving user id is not valid' })
    }

    const conversation = await Conversation.findById(convoId);
    if (!conversation) {
      return res.status(400).json({ error: 'conversation not found' });
    }

    const validMembers =
      (conversation.initiator.toString() === sender && conversation.recipient.toString() === other) ||
      (conversation.initiator.toString() === other && conversation.recipient.toString() === sender);

    if (!validMembers) {
      return res.status(400).json({ error: 'users are not part of this conversation' });
    }

    const message = new Message({
      sender,
      text: messageText,
      sentAt: Date.now(),
      read: false
    });

    await message.save();

    conversation.messages.push(message._id);
    conversation.updatedAt = Date.now();
    await conversation.save()

    res.status(200).json({
      message: 'Message sent successfully',
      messageData: {
        id: message._id.toString(),
        text: message.text,
        sender: message.sender.toString()
      }
    })

  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Server error fetching messages' });
  }
});

// GET /api/messages/getAvailableUsers?userId={userId}
router.get('/getAvailableUsers', async (req, res) => {
  try {
    const userId = req.query.userId;
    if (!userId) return res.status(400).json({ error: 'userId query required' });

    // First, find all conversations the user is part of
    const convos = await Conversation.find({
      $or: [{ initiator: userId }, { recipient: userId }]
    });

    // Build a set of userIds already in conversation with
    const connectedUserIds = new Set();
    convos.forEach(c => {
      if (c.initiator.toString() !== userId) connectedUserIds.add(c.initiator.toString());
      if (c.recipient.toString() !== userId) connectedUserIds.add(c.recipient.toString());
    });

    // Also add yourself to the set to exclude yourself
    connectedUserIds.add(userId);

    // Find all users not in the set
    const availableUsers = await User.find({
      _id: { $nin: Array.from(connectedUserIds) }
    }).select('username profilePicture');

    const formattedUsers = availableUsers.map(u => ({
      id: u._id.toString(),
      username: u.username,
      profileImageURL: u.profilePicture || null
    }));

    res.json(formattedUsers);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Server error fetching available users' });
  }
});

router.post('/startConversation', async (req, res) => {
  try {
    const { initiator, recipient, messageText } = req.body;

    if (!initiator || !recipient || !messageText) {
      return res.status(400).json({ error: 'initiator, recipient, and messageText are required.' });
    }

    // Check if a conversation already exists
    let convo = await Conversation.findOne({ initiator, recipient })
      || await Conversation.findOne({ initiator: recipient, recipient: initiator });

    if (convo) {
      return res.status(400).json({ error: 'Conversation already exists.' });
    }

    // Create the new conversation
    convo = new Conversation({ initiator, recipient, status: 'pending', acceptedAt: Date.now() });
    await convo.save();

    // Create the first message
    const message = new Message({
      sender: initiator,
      text: messageText,
      sentAt: Date.now(),
      read: false
    });
    await message.save();

    // Attach message to conversation
    convo.messages.push(message._id);
    convo.updatedAt = Date.now();
    await convo.save();

    // Populate initiator and recipient properly
    await convo.populate('initiator', 'username profilePicture');
    await convo.populate('recipient', 'username profilePicture');
    await convo.populate({
      path: 'messages',
      select: 'text sender sentAt',
      options: { sort: { sentAt: 1 } }
    });

    const other = convo.initiator._id.toString() === initiator
      ? convo.recipient
      : convo.initiator;

    const simpleMessages = convo.messages.map(msg => ({
      id: msg._id.toString(),
      text: msg.text,
      sender: msg.sender.toString()
    }));

    const lastText = simpleMessages.length
      ? simpleMessages[simpleMessages.length - 1].text
      : null;

    const formattedConversation = {
      id: convo._id.toString(),
      initiatorId: initiator,
      otherUser: {
        id: other._id.toString(),
        username: other.username,
        profilePicture: other.profilePicture || null
      },
      messages: simpleMessages,
      lastMessage: lastText,
      status: 'pending'
    };

    console.log(formattedConversation)

    res.status(201).json(formattedConversation);

  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Server error starting conversation' });
  }
});

// PATCH /api/messages/conversations/:id/status
// Body: { status: 'accepted' | 'declined', userId }
router.patch('/conversations/:id/status', async (req, res) => {
  try {
    const convId = req.params.id;
    const { status, userId } = req.body;

    if (!['accepted', 'declined'].includes(status)) {
      return res.status(400).json({ error: 'Invalid status. Must be accepted or declined.' });
    }

    if (!userId) {
      return res.status(400).json({ error: 'userId is required.' });
    }

    const convo = await Conversation.findById(convId);
    if (!convo) {
      return res.status(404).json({ error: 'Conversation not found.' });
    }

    if (convo.recipient.toString() !== userId) {
      return res.status(403).json({ error: 'Only the recipient can update the conversation status.' });
    }

    convo.status = status;
    convo.acceptedAt = status === 'accepted' ? new Date() : null;
    convo.updatedAt = new Date();
    await convo.save();

    res.status(200).json({
      message: `Conversation marked as ${status}`,
      conversationId: convo._id.toString(),
      newStatus: convo.status
    });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Server error updating conversation status' });
  }
});



module.exports = router;

