// routes/photo.js
// routes/photo.js
const express = require('express');
const cloudinary = require('../cloudinaryConfig.js'); // Adjust path if needed
const Photo = require('../Models/Photo'); // Make sure this file exists and is correct
const router = express.Router();

router.post('/uploadPhoto', async (req, res) => {
  try {
    // Expecting req.body.imageData as a Base64 string, plus optional publicId and creator.
    const { imageData, publicId, creator } = req.body;
    const dataURI = `data:image/jpeg;base64,${imageData}`; // Ensure we have the correct format for Cloudinary

    if (!imageData) {
      return res.status(400).json({ message: 'No image data provided.' });
    }
    
    // Upload the image to Cloudinary.
    const uploadResult = await cloudinary.uploader.upload(dataURI, { 
      public_id: publicId || undefined, // Let Cloudinary generate one if not provided.
    });

    // Generate an optimized URL (auto format and quality).
    const optimizeUrl = cloudinary.url(uploadResult.public_id, {
      fetch_format: 'auto',
      quality: 'auto'
    });

    // Generate an auto-cropped URL with a square aspect ratio.
    const autoCropUrl = cloudinary.url(uploadResult.public_id, {
      crop: 'auto',
      gravity: 'auto',
      width: 500,
      height: 500,
    });

    // Save the photo document in MongoDB.
    const newPhoto = new Photo({
      url: optimizeUrl,       // You can choose to store the optimized URL
      optimizedUrl: optimizeUrl,
      autoCropUrl: autoCropUrl,
      creator: creator        // Pass the creator's user ID (should be an ObjectId string)
    });
    await newPhoto.save();

    return res.status(200).json({
      uploadResult,
      optimizeUrl,
      autoCropUrl,
      photo: newPhoto
    });
  } catch (error) {
    console.error("Error uploading photo:", error);
    return res.status(500).json({ message: "Error uploading photo", error });
  }
});

router.get('/byUser/:userId', async (req, res) => {
  try {
    const { userId } = req.params;
    // Find photos where the creator field matches the given userId.
    const photos = await Photo.find({ creator: userId });
    
    // Sanitize the response: convert ObjectIDs to strings.
    const sanitizedPhotos = photos.map(photo => ({
      _id: photo._id.toString(),
      url: photo.url,
      optimizedUrl: photo.optimizedUrl,
      autoCropUrl: photo.autoCropUrl,
      creator: photo.creator ? photo.creator.toString() : null,
      createdAt: photo.createdAt
    }));
    
    // console.log("Fetched photos:", sanitizedPhotos);
    res.status(200).json(sanitizedPhotos);
  } catch (error) {
    console.error("Error fetching photos:", error);
    res.status(500).json({ message: "Error fetching photos", error });
  }
});

router.delete('/:photoId', async (req, res) => {
    try {
      const { photoId } = req.params;
      const deletedPhoto = await Photo.findByIdAndDelete(photoId);
      if (!deletedPhoto) {
        return res.status(404).json({ message: "Photo not found" });
      }
      res.status(200).json({ message: "Photo deleted successfully" });
    } catch (error) {
      console.error("Error deleting photo:", error);
      res.status(500).json({ message: "Error deleting photo", error });
    }
  });
  

module.exports = router;
