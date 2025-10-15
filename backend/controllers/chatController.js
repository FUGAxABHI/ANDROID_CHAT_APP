const Message = require('../models/Message');

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