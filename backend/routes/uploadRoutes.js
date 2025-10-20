const express = require('express');
const router = express.Router();
const uploadController = require('../controllers/uploadController');
const auth = require('../middleware/authMiddleware');

const upload = require('../middleware/upload');

router.post('/avatar', auth, upload.single('file'), uploadController.uploadAvatar);

module.exports = router;
