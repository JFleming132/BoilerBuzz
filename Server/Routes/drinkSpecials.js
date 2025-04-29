// Routes/drinkSpecials.js
const mongoose = require('mongoose');
const express = require('express');

const DrinkSpecial = require('../Models/DrinkSpecial');
const User = require('../Models/User');

/**
 * Exports a function that takes a Socket.IO server instance (`io`) and returns
 * an Express router for handling DrinkSpecial endpoints.
 */
module.exports = (io) => {
  const router = express.Router();

  /**
   * POST /api/drinkspecials
   * Create a new drink special (only for promoted/bar accounts)
   */
  router.post('/', async (req, res) => {
    try {
      const { title, author, barName, description, imageUrl, expiresAt, offers } = req.body;

      // Required fields validation
      if (!title || !author || !barName || !expiresAt) {
        return res.status(400).json({ message: 'Missing required fields: title, author, barName, or expiresAt' });
      }

      // Validate expiresAt format
      const expTs = new Date(expiresAt).getTime();
      if (isNaN(expTs)) {
        return res.status(400).json({ message: 'Invalid expiresAt timestamp' });
      }

      // Ensure author is promoted
      const user = await User.findById(author).lean();
      if (!user || !user.isPromoted) {
        return res.status(403).json({ message: 'User not authorized to create specials' });
      }

      // Validate offers array
      const offersArray = Array.isArray(offers)
        ? offers.filter(o => o.name && !isNaN(Number(o.price)))
                 .map(o => ({ name: o.name, price: Number(o.price) }))
        : [];

      const newSpecial = new DrinkSpecial({
        title,
        author,
        barName,
        description: description || '',
        imageUrl: imageUrl || '',
        offers: offersArray,
        expiresAt: expTs
      });

      const saved = await newSpecial.save();
      console.log('✅ Drink special created:', saved);

      // After your io.emit...
    const responseObj = {
        id:         saved._id.toString(),
        title:      saved.title,
        barName:    saved.barName,
        description:saved.description,
        imageUrl:   saved.imageUrl,
        offers:     saved.offers.map(o => ({ name: o.name, price: o.price })),
        createdAt:  Number(saved.createdAt),
        expiresAt:  Number(saved.expiresAt)
    };
    
    io.emit('drinkSpecialCreated', responseObj);
    
    return res.status(201).json(responseObj);
  
    } catch (err) {
      console.error('❌ Error creating drink special:', err);
      return res.status(500).json({ message: 'Error saving drink special', error: err });
    }
  });

  /**
   * GET /api/drinkspecials
   * Fetch all active specials (expiresAt > now)
   */
  router.get('/', async (req, res) => {
    try {
      const now = Date.now();
      const specials = await DrinkSpecial.find({ expiresAt: { $gt: now } }).lean();
      console.log(`✨ Found ${specials.length} active drink specials`);
      const formatted = specials.map(s => ({
        id: s._id.toString(),
        title: s.title,
        author: s.author.toString(),
        barName: s.barName,
        description: s.description || '',
        imageUrl: s.imageUrl || '',
        offers: Array.isArray(s.offers)
          ? s.offers.map(o => ({ name: o.name, price: Number(o.price) }))
          : [],
        createdAt: Number(s.createdAt),
        expiresAt: Number(s.expiresAt)
      }));
      return res.status(200).json(formatted);
    } catch (err) {
      console.error('❌ Error fetching drink specials:', err);
      return res.status(500).json({ message: 'Error fetching specials', error: err });
    }
  });

  /**
   * GET /api/drinkspecials/:id
   * Fetch a single special by its ID
   */
  router.get('/:id', async (req, res) => {
    try {
      const { id } = req.params;
      if (!mongoose.Types.ObjectId.isValid(id)) {
        return res.status(400).json({ message: 'Invalid special ID' });
      }
      const s = await DrinkSpecial.findById(id).lean();
      if (!s) {
        return res.status(404).json({ message: 'Special not found' });
      }
      const formatted = {
        id: s._id.toString(),
        title: s.title,
        author: s.author.toString(),
        barName: s.barName,
        description: s.description || '',
        imageUrl: s.imageUrl || '',
        offers: Array.isArray(s.offers)
          ? s.offers.map(o => ({ name: o.name, price: Number(o.price) }))
          : [],
        createdAt: Number(s.createdAt),
        expiresAt: Number(s.expiresAt)
      };
      return res.status(200).json(formatted);
    } catch (err) {
      console.error('❌ Error fetching special by ID:', err);
      return res.status(500).json({ message: 'Error fetching special', error: err });
    }
  });

  /**
   * GET /api/drinkspecials/bar/:barId
   * Fetch all active specials for a given bar
   */
  router.get('/bar/:barId', async (req, res) => {
    try {
      const { barId } = req.params;
      if (!mongoose.Types.ObjectId.isValid(barId)) {
        return res.status(400).json({ message: 'Invalid bar ID' });
      }
      const now = Date.now();
      const specials = await DrinkSpecial.find({
        author: barId,
        expiresAt: { $gt: now }
      }).lean();
      console.log(`🍹 Found ${specials.length} specials for bar ${barId}`);
      const formatted = specials.map(s => ({
        id: s._id.toString(),
        title: s.title,
        author: s.author.toString(),
        barName: s.barName,
        description: s.description || '',
        imageUrl: s.imageUrl || '',
        offers: Array.isArray(s.offers)
          ? s.offers.map(o => ({ name: o.name, price: Number(o.price) }))
          : [],
        createdAt: Number(s.createdAt),
        expiresAt: Number(s.expiresAt)
      }));
      return res.status(200).json(formatted);
    } catch (err) {
      console.error('❌ Error fetching bar specials:', err);
      return res.status(500).json({ message: 'Error fetching bar specials', error: err });
    }
  });

  /**
   * DELETE /api/drinkspecials/:id
   * Remove a drink special by ID
   */
  router.delete('/:id', async (req, res) => {
    try {
      const { id } = req.params;
      if (!mongoose.Types.ObjectId.isValid(id)) {
        return res.status(400).json({ message: 'Invalid special ID' });
      }
      const deleted = await DrinkSpecial.findByIdAndDelete(id);
      if (!deleted) {
        return res.status(404).json({ message: 'Drink special not found' });
      }
      console.log(`🚫 Drink special deleted: ${id}`);

      // Emit real-time deletion
      io.emit('drinkSpecialDeleted', { id });

      return res.status(200).json({ message: 'Drink special deleted successfully' });
    } catch (err) {
      console.error('❌ Error deleting drink special:', err);
      return res.status(500).json({ message: 'Error deleting special', error: err });
    }
  });

  return router;
};
