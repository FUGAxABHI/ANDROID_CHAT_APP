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

exports.getAllConversations = async (req, res) => {
    try {
        const { userId } = req.params;
        const user = await User.findById(userId);
        if (!user) {
            return res.status(404).json({ message: 'User not found' });
        }

        // Get all unique users the current user has had a conversation with
        const sentToUsers = await Message.distinct('recipient', { sender: user._id });
        const receivedFromUsers = await Message.distinct('sender', { recipient: user._id });

        const allUserIds = [...new Set([...sentToUsers, ...receivedFromUsers].map(id => id.toString()))];

        const conversations = await Promise.all(allUserIds.map(async (otherUserId) => {
            const otherUser = await User.findById(otherUserId);
            if (!otherUser) return null;

            const lastMessage = await Message.findOne({
                $or: [
                    { sender: user._id, recipient: otherUserId },
                    { sender: otherUserId, recipient: user._id },
                ],
            }).sort({ timestamp: -1 });

            const unreadCount = await Message.countDocuments({
                sender: otherUserId,
                recipient: user._id,
                isRead: false,
            });

            return {
                username: otherUser.username.trim(),
                lastMessage: lastMessage,
                unreadCount: unreadCount,
            };
        }));

        const validConversations = conversations.filter(c => c !== null);

        res.status(200).json(validConversations);
    } catch (error) {
        logger.error('Error getting all conversations:', error);
        res.status(500).json({ message: 'Error getting all conversations' });
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
        const { bio, avatar, language } = req.body;

        const user = await User.findById(userId);
        if (!user) {
            return res.status(404).json({ message: 'User not found' });
        }

        user.bio = bio || user.bio;
        user.avatar = avatar || user.avatar;
        user.language = language || user.language;

        await user.save();

        res.status(200).json({ message: 'Profile updated successfully', user });
    } catch (error) {
        logger.error('Error updating user profile:', error);
        res.status(500).json({ message: 'Error updating user profile' });
    }
};

exports.getUserProfileById = async (req, res) => {
    try {
        const { userId } = req.params;
        const user = await User.findById(userId).select('-password'); // Exclude password
        if (!user) {
            return res.status(404).json({ message: 'User not found' });
        }
        res.status(200).json({ user: { ...user.toObject(), username: user.username.trim() } });
    } catch (error) {
        logger.error('Error getting user profile by ID:', error);
        res.status(500).json({ message: 'Server error' });
    }
};

exports.uploadProfilePicture = async (req, res) => {
    try {
        if (!req.file) {
            return res.status(400).json({ message: 'No file uploaded.' });
        }

        const userId = req.user._id;
        const user = await User.findById(userId);

        if (!user) {
            return res.status(404).json({ message: 'User not found.' });
        }

        user.avatar = `/uploads/${req.file.filename}`;
        await user.save();

        res.status(200).json({ message: 'Profile picture uploaded successfully.', user: user.toObject() });
    } catch (error) {
        logger.error('Error uploading profile picture:', error);
        res.status(500).json({ message: 'Error uploading profile picture.' });
    }
};