const express = require('express');
const router = express.Router();
const userController = require('../controllers/userController');
const authMiddleware = require('../middleware/authMiddleware');

const upload = require('../middleware/upload'); // Import the upload middleware

router.get('/search', authMiddleware, userController.searchUsers);
router.get('/all-conversations/:userId', authMiddleware, userController.getAllConversations);

router.get('/profile', authMiddleware, userController.getUserProfile);
router.get('/profile/:userId', authMiddleware, userController.getUserProfileById);
router.get('/username/:username', userController.getUserByUsername);
router.put('/profile', authMiddleware, userController.updateUserProfile);
// New route for uploading profile picture
router.post('/profile', authMiddleware, upload.single('profilePicture'), userController.uploadProfilePicture);

module.exports = router;