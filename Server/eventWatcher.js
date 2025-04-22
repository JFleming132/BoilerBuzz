// eventWatcher.js
const Event = require('./Models/Event');

function startEventWatcher(io) {
  // Create a change stream on the Event collection.
  const changeStream = Event.watch(
    [], 
    {
      fullDocument:      'updateLookup',     
    fullDocumentBeforeChange: 'whenAvailable'
    }
  );
  console.log("Event watcher started. Listening for new events...");
    if (!changeStream) {
        console.error("Failed to create change stream for Event collection.");
        return;
    }

  changeStream.on('change', async (change) => {
    console.log("Change detected:", change);
    // only for insert right now (THIS IS FOR NEW POSTS)
    switch (change.operationType) {
        case 'insert': {
          const newEvent = change.fullDocument;
          io.emit('newEvent', newEvent);
          break;
        }
        case 'update': {
            const id = change.documentKey._id.toString();
            const diffs = change.updateDescription.updatedFields;

            const updatedKeys = Object.keys(diffs);
            if (updatedKeys.length === 1 && updatedKeys[0] === 'rsvpCount') {
            return;
            }

            function prettyChange(field, value) {
                switch (field) {
                  case 'title':
                    return `Title changed to “${value}”`;
                  case 'description':
                    return `Description updated`;
                  case 'location':
                    return `Location changed to “${value}”`;
                  case 'capacity':
                    return `Capacity is now ${value}`;
                  case 'is21Plus':
                    return value
                      ? `This event is now 21+`
                      : `This event is no longer 21+`;
                  case 'promoted':
                    return value
                      ? `This event is now promoted`
                      : `This event is no longer promoted`;
                  case 'date': {
                    const d = new Date(value);
                    return `Date changed to ${d.toLocaleString()}`;
                  }
                  case 'rsvpCount':
                    return `RSVP count is now ${value}`;
                  case 'imageUrl':
                    return `Event image was updated`;
                  case 'authorUsername':
                    return `Host changed to “${value}”`;
                  // you can add more cases here if needed...
                  default:
                    return `${field} updated`;
                }
            }

            const summary = Object.entries(diffs)
                .map(([k, v]) => prettyChange(k, v))
                .join('; ');

            let titleText = 'Event Updated';
            try {
                const evt = await Event.findById(id).select('title').lean();
                if (evt && evt.title) {
                titleText = `Event “${evt.title}” updated`;
                }
            } catch (err) {
                console.warn('Could not load event title for notification', err);
            }
    
            io.emit('eventUpdated', { id, title: titleText, summary });
            break;
        }

        case 'delete': {
         // before image is under `fullDocumentBeforeChange`
            const before = change.fullDocumentBeforeChange;
            console.log("Event deleted:", before);
            const title  = before?.title || 'Unknown event';
            io.emit('eventDeleted', { id: change.documentKey._id.toString(), title });
        }
      }
    });

  changeStream.on('error', (error) => {
    console.error("Error in event watcher:", error);
  });
}

module.exports = { startEventWatcher };
