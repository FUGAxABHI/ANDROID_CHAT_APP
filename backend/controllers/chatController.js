const Message = require('../models/Message');

exports.markAsRead = async (req, res) => {
  try {
    const { sender, receiver } = req.body;
    await Message.updateMany(
      { sender: sender, receiver: receiver, isRead: false },
      { $set: { isRead: true } }
    );
    res.status(200).send({ message: 'Messages marked as read' });
  } catch (error) {
    res.status(500).send({ message: 'Error marking messages as read' });
  }
};