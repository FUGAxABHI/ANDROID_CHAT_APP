const logger = require('../utils/logger');
const FriendRequest = require('../models/FriendRequest');
const User = require('../models/User');

const { notifyFriendRequest, notifyRequestAccepted } = require('../socket/friendHandler');

exports.sendFriendRequest = async (req, res) => {
  const { receiverUsername } = req.body;
  const senderId = req.user._id;

  try {
    const receiver = await User.findOne({ username: receiverUsername });
    if (!receiver) {
      return res.status(404).json({ message: 'User not found' });
    }

    if (senderId.equals(receiver._id)) {
      return res.status(400).json({ message: 'You cannot send a friend request to yourself' });
    }

    const existingRequest = await FriendRequest.findOne({
      $or: [
        { sender: senderId, receiver: receiver._id },
        { sender: receiver._id, receiver: senderId },
      ],
    });

    if (existingRequest) {
      return res.status(400).json({ message: 'Friend request already sent or you are already friends' });
    }

    const newRequest = new FriendRequest({ sender: senderId, receiver: receiver._id });
    await newRequest.save();

    // Notify the receiver in real-time
    const populatedRequest = await FriendRequest.findById(newRequest._id).populate('sender', 'username avatar');
    notifyFriendRequest(receiver.username, populatedRequest);

    res.status(200).json({ message: 'Friend request sent successfully' });
  } catch (error) {
    logger.error('Error in sendFriendRequest: ', error.message);
    res.status(500).json({ message: 'Server error' });
  }
};

exports.getFriends = async (req, res) => {
  try {
    const userId = req.user._id;
    const user = await User.findById(userId).populate('friends', 'username avatar');
    if (!user) {
        return res.status(404).json({ message: 'User not found' });
    }
    res.json(user.friends.map(friend => ({ ...friend.toObject(), username: friend.username.trim() })));
  } catch (error) {
    logger.error('Error in getFriends: ', error);
    res.status(500).json({ message: 'Server error' });
  }
};

exports.getFriendRequests = async (req, res) => {
  try {
    const userId = req.user._id;
    const requests = await FriendRequest.find({ receiver: userId, status: 'pending' })
      .populate('sender', 'username');
    res.json(requests);
  } catch (error) {
    logger.error('Error in getFriendRequests: ', error);
    res.status(500).json({ message: 'Server error' });
  }
};

exports.acceptFriendRequest = async (req, res) => {
  try {
    const { requestId } = req.params;
    const userId = req.user._id;

    const request = await FriendRequest.findById(requestId);

    if (!request) {
      return res.status(404).json({ message: 'Friend request not found' });
    }

    if (!request.receiver.equals(userId)) {
      return res.status(403).json({ message: 'You are not authorized to accept this friend request' });
    }

    request.status = 'accepted';
    await request.save();

    // Add users to each other's friends list
    const sender = await User.findById(request.sender);
    const receiver = await User.findById(request.receiver);

    sender.friends.push(receiver._id);
    receiver.friends.push(sender._id);

    await sender.save();
    await receiver.save();

    // Notify the sender that their request was accepted
    const newFriend = { _id: receiver._id, username: receiver.username, avatar: receiver.avatar };
    notifyRequestAccepted(sender.username, newFriend);

    res.status(200).json({ message: 'Friend request accepted' });
  } catch (error) {
    logger.error('Error in acceptFriendRequest: ', error);
    res.status(500).json({ message: 'Server error' });
  }
};

exports.declineFriendRequest = async (req, res) => {
  try {
    const { requestId } = req.params;
    const userId = req.user._id;

    const request = await FriendRequest.findById(requestId);

    if (!request) {
      return res.status(404).json({ message: 'Friend request not found' });
    }

    if (!request.receiver.equals(userId)) {
      return res.status(403).json({ message: 'You are not authorized to decline this friend request' });
    }

    await request.deleteOne();

    res.status(200).json({ message: 'Friend request declined' });
  } catch (error) {
    logger.error('Error in declineFriendRequest: ', error);
    res.status(500).json({ message: 'Server error' });
  }
};

exports.getMutualFriends = async (req, res) => {
    try {
        const { userId } = req.params;
        const currentUser = await User.findById(req.user._id).populate('friends');
        const otherUser = await User.findById(userId).populate('friends');

        if (!currentUser || !otherUser) {
            return res.status(404).json({ message: 'User not found' });
        }

        const currentUserFriendIds = currentUser.friends.map(friend => friend._id.toString());
        const otherUserFriendIds = new Set(otherUser.friends.map(friend => friend._id.toString()));

        const mutualFriendIds = currentUserFriendIds.filter(friendId => otherUserFriendIds.has(friendId));

        const mutualFriends = await User.find({ _id: { $in: mutualFriendIds } }).select('username avatar');

        res.json(mutualFriends);
    } catch (error) {
        logger.error('Error in getMutualFriends: ', error);
        res.status(500).json({ message: 'Server error' });
    }
};
