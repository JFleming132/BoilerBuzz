const mongoose = require('mongoose');

const mongoURI = "mongodb+srv://skonger6:Meiners1@cluster0.ytchv.mongodb.net/?retryWrites=true&w=majority&appName=Cluster0"

mongoose.connect(mongoURI, {
    useNewUrlParser: true,
    useUnifiedTopology: true,
})
.then(() => console.log("\nMongoDB connected successfully"))
.catch(err => console.log("\nMongoDB connection error:", err));

module.exports = mongoose;



