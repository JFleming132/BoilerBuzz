// migration.js
const mongoose = require('mongoose');
const User = require('./Models/User'); // Adjust the path as needed

mongoose.connect('mongodb+srv://skonger6:Meiners1@cluster0.ytchv.mongodb.net/Boiler_Buzz?retryWrites=true&w=majority&appName=Cluster0/Boiler_Buzz', { 
    useNewUrlParser: true, 
    useUnifiedTopology: true 
})
.then(async () => {
    console.log("Connected to MongoDB");

    // Update all user documents that do not have isAdmin or isBanned defined
    const result = await User.updateMany(
        { $or: [{ isAdmin: { $exists: false } }, { isBanned: { $exists: false } }] },
        { $set: { isAdmin: false, isBanned: false } }
    );

    console.log("Updated documents:", result);
    mongoose.connection.close();
})
.catch(err => {
    console.error("MongoDB connection error:", err);
});
