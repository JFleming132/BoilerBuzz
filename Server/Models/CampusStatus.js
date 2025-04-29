const mongoose = require('mongoose');

const campusStatusSchema = new mongoose.Schema({
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true,
    unique: true
  },
  isOnCampus: {
    type: Boolean,
    default: false
  },
  lastChecked: {
    type: Date,
    default: Date.now
  }
});

module.exports = mongoose.model('CampusStatus', campusStatusSchema);
