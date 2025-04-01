const mongoose = require('mongoose');

const harrysSchema = new mongoose.Schema({
    _id: String,  // Assuming "_id" is stored as a string like "harrys"
    people_in_bar: Number,
    people_in_line: Number,
    last_updated: Date
}, { collection: "harrys_count" }); // <-- Force correct collection name

module.exports = mongoose.model("HarrysCount", harrysSchema);
