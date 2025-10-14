const logger = require('../utils/logger');
const Message = require('../models/Message');
const User = require('../models/User');

exports.searchUsers = async (req, res) => {
    try {
        const query = req.query.query ? req.query.query.trim() : '';
        logger.info(`Searching for users with query: "${query}"`);
        if (!query) {
            return res.status(400).json({ message: 'Search query is required' });
        }

        const users = await User.find({
            username: { $regex: query, $options: 'i' }
        });

        res.status(200).json(users.map(user => ({ ...user.toObject(), username: user.username.trim() })));
    } catch (error) {
        logger.error('Error searching users:', error);
        res.status(500).json({ message: 'Error searching users' });
    }
};

exports.getRecentChats = async (req, res) => {
  try {
    const { userId } = req.params;
    const user = await User.findById(userId);
    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }

    const messages = await Message.find({
      $or: [{ sender: user._id }, { recipient: user._id }],
    }).sort({ timestamp: -1 }).populate('sender').populate('recipient');

    const recentChats = {};
    for (const message of messages) {
      const otherUser = message.sender._id.equals(user._id) ? message.recipient : message.sender;
      if (!otherUser) continue; // Skip public messages
      const otherUsername = otherUser.username;

      if (!recentChats[otherUsername]) {
        recentChats[otherUsername] = {
          user: otherUser,
          lastMessage: message,
          unreadCount: 0,
        };
      }
      if (message.recipient && message.recipient._id.equals(user._id) && !message.isRead) {
        recentChats[otherUsername].unreadCount++;
      }
    }

    res.status(200).json(Object.values(recentChats).map(data => ({
      username: data.user.username.trim(),
      lastMessage: data.lastMessage,
      unreadCount: data.unreadCount,
    })));
  } catch (error) {
    res.status(500).json({ message: 'Error getting recent chats' });
  }
};

exports.getUserProfile = async (req, res) => {
    try {
        const { userId } = req.params;
        const user = await User.findById(userId).populate('friends', 'username avatar');
        if (!user) {
            return res.status(404).json({ message: 'User not found' });
        }
        res.status(200).json({ ...user.toObject(), username: user.username.trim() });
    } catch (error) {
        logger.error('Error getting user profile:', error);
        res.status(500).json({ message: 'Server error' });
    }
};

exports.getUserByUsername = async (req, res) => {
    try {
        const { username } = req.params;
        logger.debug(`[getUserByUsername] Attempting to find user: ${username}`);
        const trimmedUsername = username.trim();
        const user = await User.findOne({ username: { $regex: new RegExp('^' + trimmedUsername + '$', 'i') } }).select('-password'); // Exclude password
        logger.debug(`[getUserByUsername] User.findOne result for ${trimmedUsername}: ${user ? 'found' : 'not found'}.`);
        if (!user) {
            logger.debug(`[getUserByUsername] User ${trimmedUsername} not found. Returning 404.`);
            return res.status(404).json({ message: 'User not found' });
        }
        logger.debug(`[getUserByUsername] User ${trimmedUsername} found. Returning 200.`);
        res.status(200).json({ user: { ...user.toObject(), username: user.username.trim() } });
    } catch (error) {
        logger.error('[getUserByUsername] Error getting user by username:', error.message, error.stack);
        res.status(500).json({ message: 'Server error', error: error.message, stack: error.stack });
    }
};

exports.updateUserProfile = async (req, res) => {
    try {
        const userId = req.user._id; // Correctly access the user ID
        const { bio, avatar } = req.body;

        const user = await User.findById(userId);
        if (!user) {
            return res.status(404).json({ message: 'User not found' });
        }

        user.bio = bio || user.bio;
        user.avatar = avatar || user.avatar;

        await user.save();

        res.status(200).json({ message: 'Profile updated successfully', user });
    } catch (error) {
        logger.error('Error updating user profile:', error);
        res.status(500).json({ message: 'Error updating user profile' });
    }
};