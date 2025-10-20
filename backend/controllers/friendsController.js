const logger = require('../utils/logger');
const FriendRequest = require('../models/FriendRequest');
const User = require('../models/User');

const { notifyFriendRequest, notifyRequestAccepted } = require('../socket/friendHandler');

exports.sendFriendRequest = async (req, res) => {
  logger.info('[sendFriendRequest] Send friend request function called.');
  const { receiverUsername } = req.body;
  const senderId = req.user._id;
  logger.info(`[sendFriendRequest] Sender ID: ${senderId}, Receiver Username: ${receiverUsername}`);

  try {
    const receiver = await User.findOne({ username: receiverUsername });
    if (!receiver) {
      logger.warn(`[sendFriendRequest] Receiver user not found with username: ${receiverUsername}`);
      return res.status(404).json({ message: 'User not found' });
    }

    if (senderId.equals(receiver._id)) {
      logger.warn('[sendFriendRequest] User tried to send a friend request to themselves.');
      return res.status(400).json({ message: 'You cannot send a friend request to yourself' });
    }

    const existingRequest = await FriendRequest.findOne({
      $or: [
        { sender: senderId, receiver: receiver._id },
        { sender: receiver._id, receiver: senderId },
      ],
    });

    if (existingRequest) {
      logger.warn('[sendFriendRequest] Friend request already sent or users are already friends.');
      return res.status(400).json({ message: 'Friend request already sent or you are already friends' });
    }

    const newRequest = new FriendRequest({ sender: senderId, receiver: receiver._id });
    await newRequest.save();
    logger.info(`[sendFriendRequest] Friend request from sender ID: ${senderId} to receiver ID: ${receiver._id} created.`);

    // Notify the receiver in real-time
    const populatedRequest = await FriendRequest.findById(newRequest._id).populate('sender', 'username avatar');
    notifyFriendRequest(receiver.username, populatedRequest);
    logger.info(`[sendFriendRequest] Notified receiver user: ${receiver.username}`);

    res.status(200).json({ message: 'Friend request sent successfully' });
    logger.info('[sendFriendRequest] Send friend request function finished.');
  } catch (error) {
    logger.error('[sendFriendRequest] Error in sendFriendRequest: ', error.message);
    res.status(500).json({ message: 'Server error' });
  }
};

exports.getFriends = async (req, res) => {
  logger.info('[getFriends] Get friends function called.');
  try {
    const userId = req.user._id;
    logger.info(`[getFriends] Getting friends for user ID: ${userId}`);
    const user = await User.findById(userId).populate('friends', 'username avatar');
    if (!user) {
        logger.warn(`[getFriends] User not found with ID: ${userId}`);
        return res.status(404).json({ message: 'User not found' });
    }
    logger.info(`[getFriends] Found ${user.friends.length} friends for user ID: ${userId}.`);
    res.json(user.friends.map(friend => ({ ...friend.toObject(), username: friend.username.trim() })));
    logger.info('[getFriends] Get friends function finished.');
  } catch (error) {
    logger.error('[getFriends] Error in getFriends: ', error);
    res.status(500).json({ message: 'Server error' });
  }
};

exports.getFriendRequests = async (req, res) => {
  logger.info('[getFriendRequests] Get friend requests function called.');
  try {
    const userId = req.user._id;
    logger.info(`[getFriendRequests] Getting friend requests for user ID: ${userId}`);
    const requests = await FriendRequest.find({ receiver: userId, status: 'pending' })
      .populate('sender', 'username');
    logger.info(`[getFriendRequests] Found ${requests.length} friend requests for user ID: ${userId}.`);
    res.json(requests);
    logger.info('[getFriendRequests] Get friend requests function finished.');
  } catch (error) {
    logger.error('[getFriendRequests] Error in getFriendRequests: ', error);
    res.status(500).json({ message: 'Server error' });
  }
};

exports.acceptFriendRequest = async (req, res) => {
  logger.info('[acceptFriendRequest] Accept friend request function called.');
  try {
    const { requestId } = req.params;
    const userId = req.user._id;
    logger.info(`[acceptFriendRequest] Accepting friend request with ID: ${requestId} for user ID: ${userId}`);

    const request = await FriendRequest.findById(requestId);

    if (!request) {
      logger.warn(`[acceptFriendRequest] Friend request not found with ID: ${requestId}`);
      return res.status(404).json({ message: 'Friend request not found' });
    }

    if (!request.receiver.equals(userId)) {
      logger.warn(`[acceptFriendRequest] User ID: ${userId} is not authorized to accept friend request with ID: ${requestId}`);
      return res.status(403).json({ message: 'You are not authorized to accept this friend request' });
    }

    // Find the sender and receiver
    const sender = await User.findById(request.sender);
    const receiver = await User.findById(request.receiver);

    // Add users to each other's friends list if they aren't already friends
    if (!sender.friends.includes(receiver._id)) {
        sender.friends.push(receiver._id);
    }
    if (!receiver.friends.includes(sender._id)) {
        receiver.friends.push(sender._id);
    }

    await sender.save();
    await receiver.save();
    logger.info(`[acceptFriendRequest] Users with IDs: ${sender._id} and ${receiver._id} are now friends.`);

    // Delete the friend request after it has been accepted
    await FriendRequest.findByIdAndDelete(requestId);
    logger.info(`[acceptFriendRequest] Friend request with ID: ${requestId} deleted.`);

    // Notify the sender that their request was accepted
    const newFriend = { _id: receiver._id, username: receiver.username, avatar: receiver.avatar };
    notifyRequestAccepted(sender.username, newFriend);
    logger.info(`[acceptFriendRequest] Notified sender user: ${sender.username}`);

    res.status(200).json({ message: 'Friend request accepted' });
    logger.info('[acceptFriendRequest] Accept friend request function finished.');
  } catch (error) {
    logger.error('[acceptFriendRequest] Error in acceptFriendRequest: ', error);
    res.status(500).json({ message: 'Server error' });
  }
};

exports.declineFriendRequest = async (req, res) => {
  logger.info('[declineFriendRequest] Decline friend request function called.');
  try {
    const { requestId } = req.params;
    const userId = req.user._id;
    logger.info(`[declineFriendRequest] Declining friend request with ID: ${requestId} for user ID: ${userId}`);

    const request = await FriendRequest.findById(requestId);

    if (!request) {
      logger.warn(`[declineFriendRequest] Friend request not found with ID: ${requestId}`);
      return res.status(404).json({ message: 'Friend request not found' });
    }

    if (!request.receiver.equals(userId)) {
      logger.warn(`[declineFriendRequest] User ID: ${userId} is not authorized to decline friend request with ID: ${requestId}`);
      return res.status(403).json({ message: 'You are not authorized to decline this friend request' });
    }

    await request.deleteOne();
    logger.info(`[declineFriendRequest] Friend request with ID: ${requestId} deleted.`);

    res.status(200).json({ message: 'Friend request declined' });
    logger.info('[declineFriendRequest] Decline friend request function finished.');
  } catch (error) {
    logger.error('[declineFriendRequest] Error in declineFriendRequest: ', error);
    res.status(500).json({ message: 'Server error' });
  }
};

exports.getMutualFriends = async (req, res) => {
    logger.info('[getMutualFriends] Get mutual friends function called.');
    try {
        const { userId } = req.params;
        const currentUserId = req.user._id;
        logger.info(`[getMutualFriends] Getting mutual friends between user ID: ${currentUserId} and user ID: ${userId}`);
        const currentUser = await User.findById(currentUserId).populate('friends');
        const otherUser = await User.findById(userId).populate('friends');

        if (!currentUser || !otherUser) {
            logger.warn(`[getMutualFriends] One or both users not found. Current user ID: ${currentUserId}, Other user ID: ${userId}`);
            return res.status(404).json({ message: 'User not found' });
        }

        const currentUserFriendIds = currentUser.friends.map(friend => friend._id.toString());
        const otherUserFriendIds = new Set(otherUser.friends.map(friend => friend._id.toString()));

        const mutualFriendIds = currentUserFriendIds.filter(friendId => otherUserFriendIds.has(friendId));
        logger.info(`[getMutualFriends] Found ${mutualFriendIds.length} mutual friends.`);

        const mutualFriends = await User.find({ _id: { $in: mutualFriendIds } }).select('username avatar');

        res.json(mutualFriends);
        logger.info('[getMutualFriends] Get mutual friends function finished.');
    } catch (error) {
        logger.error('[getMutualFriends] Error in getMutualFriends: ', error);
        res.status(500).json({ message: 'Server error' });
    }
};
