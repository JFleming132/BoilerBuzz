//
//  calendar.js
//  BoilerBuzz
//
//  Created by Joseph Fleming on 3/27/25.
//

const express = require('express');
const router = express.Router();
const mongoose = require('mongoose');
const { ObjectId } = require('mongodb');
const User = require('../Models/User');
const Event = require('../Models/Event'); // Ensure correct path to Event model

//TODO: write GET backend call for calendar events
//Should fetch all of a user's RSVP'd events, all events that are promoted, then filter out those whose author's userIDs are in a user's blockedUserIDs list
//can probably write an aggregate function in mongoDB to do all that

router.get('/events', async (req, res) => {
    try {
        console.log("got request with query:", req.query);
        const currentUserID = req.query.currentUserID;
        const currentDate = new Date().getTime();
        currentUserObjectID = new ObjectId(currentUserID);
        if (!mongoose.Types.ObjectId.isValid(currentUserID)) {
            console.log(currentUserID + " is not valid")
            return res.status(400).json({ error: 'Invalid user Id(s)' });
        }
        const db = req.app.locals.db || mongoose.connection.client.db('Boiler_Buzz');

        const events = await User.aggregate([
                                             //This aggregate took me like 4 hours
                                             //Essentially, it returns all events which a user has RSVPd too
                                             //and all events that are promoted
                                             //except those events which have been posted by authors
                                             //which the user has blocked
            {
                $project: {
                    blockedUserIDs: {
                        $map: {
                            input: "$blockedUserIDs",
                            as: "blocks",
                            in: {
                                $toObjectId: "$$blocks"
                            }
                        }
                    },
                    rsvpEventID: {
                        $map: {
                            input: "$rsvpEvents",
                            as: "event",
                            in: {$toObjectId: "$$event"}
                        }
                    }
                }
            }, {
                $lookup: {
                    from: "events",
                    let: {
                        rsvp: "$rsvpEventID",
                        blocked: "$blockedUserIDs"
                    },
                    pipeline: [
                        {
                            $set: {
                                rsvp: "$$rsvp",
                                blocked: "$$blocked"
                            }
                        },
                        {
                            $match: {
                                $expr: {
                                    $and: [
                                        {
                                            $or: [
                                                {
                                                    $in:
                                                    [
                                                        "$_id", "$$rsvp"
                                                    ]
                                                },
                                                {
                                                    $eq: [
                                                        "$promoted", true
                                                    ]
                                                }
                                            ]
                                        },
                                        {
                                            $not: {
                                                $in: [
                                                    "$author", {
                                                        $ifNull: [
                                                            "$$blocked",
                                                            []
                                                        ]
                                                    }
                                                ]
                                            }
                                        }
                                    ]
                                }
                            }
                        }
                    ],
                    as: "validEvents"
                }
            }, {
                $match: {
                    _id: currentUserObjectID
                }
            }, {
                $unwind: {
                    path: "$validEvents"
                }
            }, {
                $replaceRoot: {
                    newRoot: "$validEvents"
                }
            }
        ]);
        //console.log("got events:", events);
        const sanitizedEvents = events.map(event => ({
            ...event,
            imageUrl: event.imageUrl || "" // ✅ Ensure imageUrl is always a string
        }));

        console.log("Fetching events from DB:", sanitizedEvents);
        res.json(sanitizedEvents);
    } catch (err) {
        console.error("Error fetching events:", err);
        res.status(500).json({ message: 'Error fetching events', error: err });
    }
});

module.exports = router;
