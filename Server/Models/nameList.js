const mongoose = require('mongoose');

const nameListSchema = new mongoose.Schema({
  username: {
    type: String,
    required: true,
    unique: true,
    ref: 'User'
  },
  firstName: {
    type: String,
    required: true
  },
  lastName: {
    type: String,
    required: true
  }
});

// Critical Fix: Check if model already exists
module.exports = mongoose.models.NameList || mongoose.model('NameList', nameListSchema);

