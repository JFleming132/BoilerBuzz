// eventWatcher.js
const Event = require('./Models/Event');

function startEventWatcher(io) {
  // Create a change stream on the Event collection.
  const changeStream = Event.watch();
  console.log("Event watcher started. Listening for new events...");
    if (!changeStream) {
        console.error("Failed to create change stream for Event collection.");
        return;
    }

  changeStream.on('change', (change) => {
    console.log("Change detected:", change);
    // We are only interested in new events (insert operations)
    if (change.operationType === 'insert') {
      const newEvent = change.fullDocument;
      console.log("New event inserted:", newEvent);
      // Broadcast the new event to all connected clients via websockets.
      io.emit('newEvent', newEvent);
    }
  });

  changeStream.on('error', (error) => {
    console.error("Error in event watcher:", error);
  });
}

module.exports = { startEventWatcher };
