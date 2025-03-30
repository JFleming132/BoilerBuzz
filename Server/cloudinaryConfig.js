// cloudinaryConfig.js
const cloudinary = require('cloudinary').v2;

cloudinary.config({ 
  cloud_name: 'djzhrzjoq', 
  api_key: '736513755228875', 
  api_secret: '7m4VHYzYzYHDYOAGOF8YvyZs1Fc' // may need to store this in env
});

module.exports = cloudinary;