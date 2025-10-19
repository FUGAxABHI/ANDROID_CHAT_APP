const multer = require('multer');
const path = require('path');
const User = require('../models/User'); // Import User model

// Set up storage for uploaded files
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    cb(null, 'uploads/');
  },
  filename: (req, file, cb) => {
    cb(null, Date.now() + path.extname(file.originalname));
  },
});

const upload = multer({ storage: storage });

exports.uploadFile = [
  upload.single('file'),
  (req, res) => {
    if (!req.file) {
      return res.status(400).json({ message: 'No file uploaded.' });
    }
    // Return the path to the uploaded file
    const fileUrl = `/uploads/${req.file.filename}`;
    res.status(200).json({ url: fileUrl });
  },
];

exports.uploadAvatar = async (req, res) => {
  try {
    if (!req.file) {
      return res.status(400).json({ message: 'No avatar file uploaded.' });
    }

    const userId = req.user.id; // Assuming user ID is available from auth middleware
    const user = await User.findById(userId);

    if (!user) {
      return res.status(404).json({ message: 'User not found.' });
    }

    const avatarUrl = `/uploads/${req.file.filename}`;
    user.avatar = avatarUrl;
    await user.save();

    res.status(200).json({ message: 'Avatar uploaded successfully', avatarUrl });
  } catch (error) {
    console.error('Error uploading avatar:', error);
    res.status(500).json({ message: 'Server error during avatar upload.' });
  }
};
