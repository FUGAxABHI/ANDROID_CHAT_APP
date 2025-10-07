const logger = require('../utils/logger');
const express = require('express');
const router = express.Router();
const userController = require('../controllers/userController');

router.get('/search', userController.searchUsers);
router.get('/recent-chats/:userId', userController.getRecentChats);

module.exports = router;