# BoilerBuzz

BoilerBuzz is a social events app designed for Purdue University students. The app focuses on showcasing social events at bars and parties and helps users keep track of what drinks they've tried. In addition to profile management (editing your profile picture, username, and bio) and a drinks page (with drink details such as calories, ingredients, and description), upcoming features include event listings, maps, and calendars.

> **Note:** This project is currently under active development and runs locally on your machine.

---

## Table of Contents

- [Features](#features)
- [Project Structure](#project-structure)
- [Requirements](#requirements)
- [Installation & Setup](#installation--setup)
- [Running the Project](#running-the-project)
- [Development Notes](#development-notes)
- [Upcoming Features](#upcoming-features)
- [License](#license)

---

## Features

- **Profile Management:**
  - Edit profile picture, username, and bio.
- **Drinks Page:**
  - Browse drinks available at various bars.
  - View drink details including calories, ingredients, and description.
  - Mark drinks as "tried" to keep track of which ones you've sampled.
- **(Upcoming)** Event listings, maps, and calendars for party/event management.

---

## Project Structure

The repository contains both the iOS frontend and the Node.js backend:

---

## Requirements

### Frontend

- **Xcode:** Latest stable version recommended.
- **iOS Device or Simulator:** If using a real device, ensure Developer Mode is enabled and your device is trusted.
- **Swift 5 / SwiftUI**

### Backend

- **Node.js:** Latest LTS version recommended.
- **npm:** Comes with Node.js.
- **MongoDB:** Local installation is required. [MongoDB Compass](https://www.mongodb.com/products/compass) is recommended for visual management.

---

## Installation & Setup

### 1. Clone the Repository

```bash
git clone https://github.com/JFleming132/BoilerBuzz.git
cd BoilerBuzz
```

### 2. Backend Setup

1. Navigate to the `server` folder:

   ```bash
   cd server
   ```

2. Install dependencies:

   ```bash
   npm install
   ```

3. Database:

Ensure MongoDB is running locally. You can use MongoDB Compass to inspect your database. The backend should connect automatically if configured properly.

## Frontend Setup

1. Open the Xcode project located in the BoilerBuzz folder.

2. Connect your development device (or use the iOS Simulator).

> **Note:** If using a real device, ensure it is trusted by your Mac and Developer Mode is enabled.

## Running the Project

#### Backend

1. Open a terminal, navigate to the `server` folder, and start the backend server:

   ```bash
   npm start
   ```

Alternatively, for automatic restarts during development:

    npx nodemon server.js

The backend runs on `http://localhost:3000` by default.  
**Note:** If testing on a real device, update any API URLs in the iOS code to use your computer’s IP address.

#### Frontend

1. Open the Xcode project.
2. Build and run the project from Xcode.
3. The app should launch on your simulator or connected device and connect to the local backend.

---

## Development Notes

- **Profile Data Handling:**  
  The app uses a shared observable object (`ProfileViewModel`) to store and update profile data (username, bio, userId). This ensures that changes made in one view (such as AccountSettingsView) are immediately reflected across the app.

- **API Endpoints:**  
  The backend provides endpoints for retrieving and updating user profile information:

  - `GET /api/profile/:userId`
  - `PUT /api/profile/:userId`

- **Local Development:**  
  The backend is accessed at `http://localhost:3000` by default. When testing on a physical device, update these URLs to use your computer’s local IP address.

- **Known Issues:**

  - Some warnings regarding CoreGraphics or text input may appear during development (e.g., when a text field is empty). These are typically harmless.
  - Future improvements include adding tests and moving to a production-ready environment.

- **Running on Real Devices:**  
  If using a real device, remember to update API URLs from `localhost` to your computer's IP address.

---

## Upcoming Features

- **Event Listings:** Users can post and browse events.
- **Map Integration:** Display events and bars on an interactive map.
- **Calendar Integration:** View upcoming events and manage RSVPs.
- **Additional Social Features:** Enhanced friend management and social feeds.

_(More details will be added as development progresses.)_

---

## License

_(Add your preferred license information here.)_
