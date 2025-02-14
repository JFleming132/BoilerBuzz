//
//  profile.js
//  BoilerBuzz
//
//  Created by Patrick Barry on 2/13/25.
//

const express = require('express');
const User = require('../Models/User');
const router = express.Router();


// ✅ Route to GET user profile details (Username & Bio) using the MongoDB _id
router.get('/:userId', async (req, res) => {
    try {
        const user = await User.findById(req.params.userId).select('username bio');
        if (!user) {
            return res.status(404).json({ message: "User not found" });
        }
        res.status(200).json(user);
    } catch (error) {
        console.error("Error fetching profile:", error);
        res.status(500).json({ message: "Internal server error" });
    }
});

module.exports = router;