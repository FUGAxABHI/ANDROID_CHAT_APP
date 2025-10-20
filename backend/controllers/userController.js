const logger = require('../utils/logger');
const Message = require('../models/Message');
const User = require('../models/User');

exports.searchUsers = async (req, res) => {
    logger.info('[searchUsers] Search users function called.');
    try {
        const query = req.query.query ? req.query.query.trim() : '';
        logger.info(`[searchUsers] Searching for users with query: "${query}"`);
        if (!query) {
            logger.warn('[searchUsers] Search query is required.');
            return res.status(400).json({ message: 'Search query is required' });
        }

        const users = await User.find({
            username: { $regex: query, $options: 'i' }
        });
        logger.info(`[searchUsers] Found ${users.length} users.`);

        res.status(200).json(users.map(user => ({ ...user.toObject(), username: user.username.trim() })));
        logger.info('[searchUsers] Search users function finished.');
    } catch (error) {
        logger.error('[searchUsers] Error searching users:', error);
        res.status(500).json({ message: 'Error searching users' });
    }
};

exports.getAllConversations = async (req, res) => {
    logger.info('[getAllConversations] Get all conversations function called.');
    try {
        const { userId } = req.params;
        logger.info(`[getAllConversations] Getting all conversations for user ID: ${userId}`);
        const user = await User.findById(userId);
        if (!user) {
            logger.warn(`[getAllConversations] User not found with ID: ${userId}`);
            return res.status(404).json({ message: 'User not found' });
        }

        // Get all unique users the current user has had a conversation with
        const sentToUsers = await Message.distinct('recipient', { sender: user._id });
        const receivedFromUsers = await Message.distinct('sender', { recipient: user._id });

        const allUserIds = [...new Set([...sentToUsers, ...receivedFromUsers].map(id => id.toString()))];
        logger.info(`[getAllConversations] Found ${allUserIds.length} unique users in conversations.`);

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
        logger.info(`[getAllConversations] Returning ${validConversations.length} conversations.`);

        res.status(200).json(validConversations);
        logger.info('[getAllConversations] Get all conversations function finished.');
    } catch (error) {
        logger.error('[getAllConversations] Error getting all conversations:', error);
        res.status(500).json({ message: 'Error getting all conversations' });
    }
};

exports.getUserProfile = async (req, res) => {
    logger.info('[getUserProfile] Get user profile function called.');
    try {
        const { userId } = req.params;
        logger.info(`[getUserProfile] Getting user profile for user ID: ${userId}`);
        const user = await User.findById(userId).populate('friends', 'username avatar');
        if (!user) {
            logger.warn(`[getUserProfile] User not found with ID: ${userId}`);
            return res.status(404).json({ message: 'User not found' });
        }
        res.status(200).json({ ...user.toObject(), username: user.username.trim() });
        logger.info(`[getUserProfile] User profile for user ID: ${userId} sent.`);
    } catch (error) {
        logger.error('[getUserProfile] Error getting user profile:', error);
        res.status(500).json({ message: 'Server error' });
    }
};

exports.getUserByUsername = async (req, res) => {
    logger.info('[getUserByUsername] Get user by username function called.');
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
        logger.info(`[getUserByUsername] User ${trimmedUsername} found and sent.`);
    } catch (error) {
        logger.error('[getUserByUsername] Error getting user by username:', error.message, error.stack);
        res.status(500).json({ message: 'Server error', error: error.message, stack: error.stack });
    }
};

exports.updateUserProfile = async (req, res) => {
    logger.info('[updateUserProfile] Update user profile function called.');
    try {
        const userId = req.user._id; // Correctly access the user ID
        logger.info(`[updateUserProfile] Updating user profile for user ID: ${userId}`);
        const { bio, avatar, language } = req.body;
        logger.info(`[updateUserProfile] Update data: bio=${bio}, avatar=${avatar}, language=${language}`);

        const user = await User.findById(userId);
        if (!user) {
            logger.warn(`[updateUserProfile] User not found with ID: ${userId}`);
            return res.status(404).json({ message: 'User not found' });
        }

        user.bio = bio || user.bio;
        user.avatar = avatar || user.avatar;
        user.language = language || user.language;

        await user.save();
        logger.info(`[updateUserProfile] User profile for user ID: ${userId} updated successfully.`);

        res.status(200).json({ message: 'Profile updated successfully', user });
        logger.info('[updateUserProfile] Update user profile function finished.');
    } catch (error) {
        logger.error('[updateUserProfile] Error updating user profile:', error);
        res.status(500).json({ message: 'Error updating user profile' });
    }
};

exports.getUserProfileById = async (req, res) => {
    logger.info('[getUserProfileById] Get user profile by ID function called.');
    try {
        const { userId } = req.params;
        logger.info(`[getUserProfileById] Getting user profile for user ID: ${userId}`);
        const user = await User.findById(userId).select('-password'); // Exclude password
        if (!user) {
            logger.warn(`[getUserProfileById] User not found with ID: ${userId}`);
            return res.status(404).json({ message: 'User not found' });
        }
        res.status(200).json({ user: { ...user.toObject(), username: user.username.trim() } });
        logger.info(`[getUserProfileById] User profile for user ID: ${userId} sent.`);
    } catch (error) {
        logger.error('[getUserProfileById] Error getting user profile by ID:', error);
        res.status(500).json({ message: 'Server error' });
    }
};

exports.uploadProfilePicture = async (req, res) => {
    logger.info('[uploadProfilePicture] Upload profile picture function called.');
    try {
        if (!req.file) {
            logger.warn('[uploadProfilePicture] No file uploaded.');
            return res.status(400).json({ message: 'No file uploaded.' });
        }
        logger.info(`[uploadProfilePicture] File uploaded: ${req.file.filename}`);

        const userId = req.user._id;
        logger.info(`[uploadProfilePicture] Updating profile picture for user ID: ${userId}`);
        const user = await User.findById(userId);

        if (!user) {
            logger.warn(`[uploadProfilePicture] User not found with ID: ${userId}`);
            return res.status(404).json({ message: 'User not found.' });
        }

        user.avatar = `/uploads/${req.file.filename}`;
        await user.save();
        logger.info(`[uploadProfilePicture] Profile picture for user ID: ${userId} updated successfully.`);

        res.status(200).json({ message: 'Profile picture uploaded successfully.', user: user.toObject() });
        logger.info('[uploadProfilePicture] Upload profile picture function finished.');
    } catch (error) {
        logger.error('[uploadProfilePicture] Error uploading profile picture:', error);
        res.status(500).json({ message: 'Error uploading profile picture.' });
    }
};