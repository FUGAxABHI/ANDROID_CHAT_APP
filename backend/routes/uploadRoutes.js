const express = require('express');
const router = express.Router();
const uploadController = require('../controllers/uploadController');
const auth = require('../middleware/authMiddleware');

router.post('/', auth, uploadController.uploadFile);

module.exports = router;
