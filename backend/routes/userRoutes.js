const express = require('express');
const router = express.Router();
const userController = require('../controllers/userController');
const authMiddleware = require('../middleware/authMiddleware');

router.get('/search', authMiddleware, userController.searchUsers);
router.get('/recent-chats/:userId', authMiddleware, userController.getRecentChats);

router.get('/profile', authMiddleware, userController.getUserProfile);
router.get('/username/:username', userController.getUserByUsername);
router.put('/profile', authMiddleware, userController.updateUserProfile);

module.exports = router;