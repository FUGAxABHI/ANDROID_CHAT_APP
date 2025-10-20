const User = require('../models/User'); // Import User model
const logger = require('../utils/logger'); // Import logger

exports.uploadAvatar = async (req, res) => {
  logger.info('uploadAvatar function called.');

  try {
    if (!req.file) {
      logger.error('No avatar file uploaded.');
      return res.status(400).json({ message: 'No avatar file uploaded.' });
    }

    logger.info(`File received: ${req.file.originalname}`);
    logger.info(`File details: ${JSON.stringify(req.file)}`);


    const userId = req.user.id; // Assuming user ID is available from auth middleware
    logger.info(`User ID: ${userId}`);

    const user = await User.findById(userId);

    if (!user) {
      logger.error(`User not found with ID: ${userId}`);
      return res.status(404).json({ message: 'User not found.' });
    }

    const avatarUrl = `/uploads/${req.file.filename}`;
    logger.info(`New avatar URL: ${avatarUrl}`);

    user.avatar = avatarUrl;
    await user.save();
    logger.info(`User avatar updated successfully for user ID: ${userId}`);

    res.status(200).json({ message: 'Avatar uploaded successfully', avatarUrl });
  } catch (error) {
    logger.error('Error uploading avatar:', error);
    res.status(500).json({ message: 'Server error during avatar upload.' });
  }
};
