const { MongoClient } = require("mongodb");

// MongoDB connection URI
const uri = "mongodb+srv://skonger6:Meiners1@cluster0.ytchv.mongodb.net/Boiler_Buzz?retryWrites=true&w=majority&appName=Cluster0";
const client = new MongoClient(uri);

async function runAggregation() {
    try {
        await client.connect();
        const db = client.db("Boiler_Buzz");
        const userLocations = db.collection("user_locations");

        // Define bar and line areas using GeoJSON polygons
        const orangeRectangle = {
            type: "Polygon",
            coordinates: [[
                [40.423906680379226, -86.9090992677956], // Top left
                [40.4239133164868, -86.90898661502665], // Top right
                [40.423730568054644, -86.90898996778762], // Bottom right
                [40.42374843454338, -86.90910664386975], // Bottom left
                [40.423906680379226, -86.9090992677956]  // Close the polygon
            ]]
        };

        const purpleEllipse = {
            type: "Polygon",
            coordinates: [[
                [40.423917364969796, -86.90914319944035], 
                [40.42390511369452, -86.90910833072614], 
                [40.42373022937806, -86.90910813366838], 
                [40.423650746756415, -86.90903272797495], 
                [40.42360806160602, -86.90917290522555],
                [40.423917364969796, -86.90914319944035]  // Close the polygon
            ]]
        };

        const aggregationPipeline = [
            {
                $match: {
                    lastUpdate: {
                        $gte: new Date(new Date().getTime() - 1000 * 60 * 10) // Last 10 min
                    }
                }
            },
            {
                $project: {
                    location: {
                        type: "Point",
                        coordinates: ["$latitude", "$longitude"]
                    },
                    lastUpdate: 1
                }
            },
            {
                $facet: {
                    people_in_bar: [
                        {
                            $match: {
                                location: {
                                    $geoWithin: {
                                        $geometry: orangeRectangle
                                    }
                                }
                            }
                        },
                        { $count: "count" }
                    ],
                    people_in_line: [
                        {
                            $match: {
                                location: {
                                    $geoWithin: {
                                        $geometry: purpleEllipse
                                    }
                                }
                            }
                        },
                        { $count: "count" }
                    ]
                }
            },
            {
                $project: {
                    _id: "harrys", // Ensure a single document
                    people_in_bar: { $ifNull: [{ $arrayElemAt: ["$people_in_bar.count", 0] }, 0] },
                    people_in_line: { $ifNull: [{ $arrayElemAt: ["$people_in_line.count", 0] }, 0] },
                    last_updated: new Date()
                }
            },
            {
                $merge: {
                    into: "harrys_count",
                    on: "_id",
                    whenMatched: "merge",
                    whenNotMatched: "insert"
                }
            }
        ];

        await userLocations.aggregate(aggregationPipeline).toArray();
    } catch (error) {
        console.error("Error running aggregation:", error);
    } finally {
        await client.close();
    }
}

// Run the aggregation script
runAggregation().catch(err => console.error("Unhandled error:", err));
