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
    // only for insert right now (THIS IS FOR NEW POSTS)
    if (change.operationType === 'insert') {
      const newEvent = change.fullDocument;
      console.log("New event inserted:", newEvent);
      io.emit('newEvent', newEvent);
    }
  });

  changeStream.on('error', (error) => {
    console.error("Error in event watcher:", error);
  });
}

module.exports = { startEventWatcher };
