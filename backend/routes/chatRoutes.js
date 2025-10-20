const express = require('express');
const router = express.Router();
const chatController = require('../controllers/chatController');
const authMiddleware = require('../middleware/authMiddleware');

router.post('/markAsRead', authMiddleware, chatController.markAsRead);
router.get('/messages/:friendId', authMiddleware, chatController.getMessages);

module.exports = router;