const mongoose = require('mongoose');

const messageSchema = new mongoose.Schema({
  sender: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  recipient: { type: mongoose.Schema.Types.ObjectId, ref: 'User' }, // Can be null for public/group chats
  message: { type: String, required: true }, // Text message or a URL/identifier for media
  timestamp: { type: Date, default: Date.now },
  isRead: { type: Boolean, default: false },
  readAt: { type: Date },
  // Fields for voice and other media
  isVoice: { type: Boolean, default: false },
  voiceData: { type: Buffer }, // To store voice data directly
  mediaUrl: { type: String }, // For storing URLs to media files (e.g., from a cloud storage)
  mediaType: { type: String, enum: ['image', 'video', 'file'] } // To distinguish between different media types
});

const Message = mongoose.model('Message', messageSchema);

module.exports = Message;
