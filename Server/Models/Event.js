const mongoose = require('mongoose');

const EventSchema = new mongoose.Schema({
    //Done: Add Author, RSVPcount, and Promoted status
    title: { type: String, required: true },
    author: { type: String, required: true},
    rsvpCount: {type: Number, required: true},
    description: { type: String },
    location: { type: String, required: true },
    capacity: { type: Number, required: true },
    is21Plus: { type: Boolean, default: false },
    promoted: { type: Boolean, default: false},
    date: { type: Number, required: true },  // ✅ Store as Unix timestamp (milliseconds)
    imageUrl: { type: String }
});

module.exports = mongoose.model('Event', EventSchema);

