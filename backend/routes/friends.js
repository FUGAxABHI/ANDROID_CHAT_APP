const express = require('express');
const router = express.Router();
const friendsController = require('../controllers/friendsController');
const auth = require('../middleware/authMiddleware');

// Send a friend request
router.post('/request', auth, friendsController.sendFriendRequest);

// Get all friends
router.get('/', auth, friendsController.getFriends);

// Get pending friend requests
router.get('/requests', auth, friendsController.getFriendRequests);

// Accept a friend request
router.post('/requests/:requestId/accept', auth, friendsController.acceptFriendRequest);

// Decline a friend request
router.post('/requests/:requestId/decline', auth, friendsController.declineFriendRequest);

// Get mutual friends
router.get('/mutual/:userId', auth, friendsController.getMutualFriends);

module.exports = router;
