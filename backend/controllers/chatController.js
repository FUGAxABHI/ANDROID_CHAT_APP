const Message = require('../models/Message');
const User = require('../models/User'); // Import User model
const logger = require('../utils/logger');

exports.markAsRead = async (req, res) => {
  const { sender, receiver } = req.body;
  logger.info(`[MarkAsRead] Marking messages as read from sender: ${sender} to receiver: ${receiver}`);
  try {
    const updateResult = await Message.updateMany(
      { sender: sender, receiver: receiver, isRead: false },
      { $set: { isRead: true } }
    );
    logger.info(`[MarkAsRead] Update result: ${updateResult.nModified} messages marked as read.`);
    res.status(200).send({ message: 'Messages marked as read' });
  } catch (error) {
    logger.error(`[MarkAsRead] Error marking messages as read for sender: ${sender}, receiver: ${receiver}:`, error.message, error.stack);
    res.status(500).send({ message: 'Error marking messages as read', error: error.message });
  }
};

exports.getMessages = async (req, res) => {
  try {
    const currentUserId = req.user._id; // From authMiddleware
    const { friendId } = req.params;

    // Find messages between currentUserId and friendId
    const messages = await Message.find({
      $or: [
        { sender: currentUserId, recipient: friendId },
        { sender: friendId, recipient: currentUserId },
      ],
    }).sort({ timestamp: 1 })
      .populate('sender', 'username') // Populate sender's username
      .populate('recipient', 'username'); // Populate recipient's username

    res.status(200).json(messages);
  } catch (error) {
    logger.error('[getMessages] Error fetching messages:', error.message, error.stack);
    res.status(500).json({ message: 'Error fetching messages', error: error.message });
  }
};