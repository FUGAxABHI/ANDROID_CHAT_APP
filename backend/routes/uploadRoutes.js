const express = require('express');
const router = express.Router();
const uploadController = require('../controllers/uploadController');
const auth = require('../middleware/authMiddleware');

const upload = require('../middleware/upload');

router.post('/', auth, uploadController.uploadFile);
router.post('/avatar', auth, upload.single('avatar'), uploadController.uploadAvatar);

module.exports = router;
