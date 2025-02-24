//
//  spending.js
//  BoilerBuzz
//
//  Created by Matt Zlatniski on 2/19/25.
//

const express = require('express');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const User = require('../Models/User');
const nodemailer = require('nodemailer');
const crypto = require('crypto');
const mongoose = require('mongoose');

const router = express.Router();

// Add expense for a user and update currentSpent
router.post('/addExpense/:userId', async (req, res) => {
    try {
        const { userId } = req.params;
        const { name, amount } = req.body;

        if (!name || !amount) {
            return res.status(400).json({ message: "Expense name and amount are required." });
        }

        if (amount.toString().split('.')[1] && amount.toString().split('.')[1].length > 2) {
            return res.status(400).json({ message: "Amount cannot have more than two decimal places." });
        }

        const user = await User.findById(userId);

        if (!user) {
            return res.status(404).json({ message: "User not found." });
        }

        user.expenses.push({ name, amount, date: new Date() });
        user.currentSpent += amount;

        await user.save();

        res.status(200).json({ message: "Expense added successfully." });
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: "An error occurred while adding the expense." });
    }
});

// Fetch the user's limit, currentSpent, and expenses
router.get('/getUserDetails/:userId', async (req, res) => {
    try {
        const { userId } = req.params;

        const user = await User.findById(userId);

        if (!user) {
            return res.status(404).json({ message: "User not found." });
        }
        

        res.status(200).json({
            limit: user.spendLimit,
            currentSpent: user.currentSpent,
            expenses: user.expenses,
        });
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: "An error occurred while fetching user details." });
    }
});

// Edit the user's spending limit
router.put('/editLimit/:userId', async (req, res) => {
    try {
        const { userId } = req.params;
        const { newLimit } = req.body;
        
        console.log(newLimit);

        if (!newLimit || newLimit <= 0) {
            return res.status(400).json({ message: "A valid spending limit is required." });
        }

        if (newLimit.toString().split('.')[1] && newLimit.toString().split('.')[1].length > 2) {
            return res.status(400).json({ message: "Spending limit cannot have more than two decimal places." });
        }

        const user = await User.findById(userId);

        if (!user) {
            return res.status(404).json({ message: "User not found." });
        }

        user.spendLimit = newLimit;

        await user.save();

        res.status(200).json({ message: "Spending limit updated successfully." });
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: "An error occurred while updating the spending limit." });
    }
});




module.exports = router;

