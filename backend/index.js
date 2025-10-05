const express = require('express');
const http = require('http');
const socketIo = require('socket.io');
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const cors = require('cors');

const app = express();
const server = http.createServer(app);
const io = socketIo(server);

const SECRET_KEY = 'your_secret_key'; // Replace with a strong, environment-variable-based secret in production

app.use(express.json()); // For parsing application/json
app.use(cors()); // Enable CORS for all routes

const users = []; // In-memory user store. In a real app, use a database.

// Registration Endpoint
app.post('/register', async (req, res) => {
  const { username, password } = req.body;

  if (!username || !password) {
    return res.status(400).json({ message: 'Username and password are required' });
  }

  if (users.find(user => user.username === username)) {
    return res.status(409).json({ message: 'Username already exists' });
  }

  try {
    const hashedPassword = await bcrypt.hash(password, 10);
    const newUser = { username, password: hashedPassword, friends: [], pendingRequests: [], privateMessages: {} };
    users.push(newUser);
    res.status(201).json({ message: 'User registered successfully' });
  } catch (error) {
    res.status(500).json({ message: 'Error registering user', error: error.message });
  }
});

// Login Endpoint
app.post('/login', async (req, res) => {
  const { username, password } = req.body;

  if (!username || !password) {
    return res.status(400).json({ message: 'Username and password are required' });
  }

  const user = users.find(u => u.username === username);
  if (!user) {
    return res.status(401).json({ message: 'Invalid credentials' });
  }

  try {
    const isPasswordValid = await bcrypt.compare(password, user.password);
    if (!isPasswordValid) {
      return res.status(401).json({ message: 'Invalid credentials' });
    }

    const token = jwt.sign({ username: user.username }, SECRET_KEY, { expiresIn: '1h' });
    res.status(200).json({ message: 'Logged in successfully', token });
  } catch (error) {
    res.status(500).json({ message: 'Error logging in', error: error.message });
  }
});

const messages = []; // Stores message history
const connectedUsers = {}; // Stores connected users: socket.id -> username

app.get('/api/users/search', (req, res) => {
  const query = req.query.q;
  if (!query) {
    return res.status(400).json({ message: 'Query parameter "q" is required' });
  }

  const searchResults = users
    .filter(user => user.username.toLowerCase().includes(query.toLowerCase()))
    .map(user => user.username);

  console.log('Search query:', query, 'Results:', searchResults); // Debug log

  res.json(searchResults);
});

app.post('/api/friends/request', authenticateToken, (req, res) => {
  const { receiverUsername } = req.body;
  const senderUsername = req.user.username; // From authenticateToken middleware

  if (!receiverUsername) {
    return res.status(400).json({ message: 'Receiver username is required' });
  }

  const receiver = users.find(u => u.username === receiverUsername);
  if (!receiver) {
    return res.status(404).json({ message: 'Receiver not found' });
  }

  if (senderUsername === receiverUsername) {
    return res.status(400).json({ message: 'Cannot send friend request to yourself' });
  }

  // Check if already friends
  if (receiver.friends && receiver.friends.includes(senderUsername)) {
    return res.status(400).json({ message: 'Already friends' });
  }

  // Check if request already sent
  if (receiver.pendingRequests && receiver.pendingRequests.includes(senderUsername)) {
    return res.status(400).json({ message: 'Friend request already sent' });
  }

  // Add sender to receiver's pending requests
  if (!receiver.pendingRequests) {
    receiver.pendingRequests = [];
  }
  receiver.pendingRequests.push(senderUsername);

  console.log(`Friend request sent from ${senderUsername} to ${receiverUsername}. Receiver pending requests:`, receiver.pendingRequests);
  res.status(200).json({ message: 'Friend request sent successfully' });
});

// Middleware to authenticate JWT token for Socket.IO connections
io.use(async (socket, next) => {
  const token = socket.handshake.auth.token;
  if (!token) {
    return next(new Error('Authentication error: Token not provided'));
  }
  try {
    const decoded = jwt.verify(token, SECRET_KEY);
    socket.user = decoded; // Attach user info to socket
    next();
  } catch (err) {
    next(new Error('Authentication error: Invalid token'));
  }
});

// Socket.IO setup
io.on('connection', (socket) => {
  console.log('a user connected');

  // Send message history to the newly connected user
  socket.emit('message history', messages);

  socket.on('set username', (username) => {
    connectedUsers[socket.id] = username;
    io.emit('user joined', username);
    console.log(`${username} joined the chat`);
  });

  socket.on('private message', ({ to, message }) => {
    const senderUsername = socket.user.username; // Get sender from authenticated socket
    const messageData = { sender: senderUsername, message, timestamp: new Date() };

    // Store message for sender
    const senderUser = users.find(u => u.username === senderUsername);
    if (senderUser) {
      if (!senderUser.privateMessages[to]) {
        senderUser.privateMessages[to] = [];
      }
      senderUser.privateMessages[to].push(messageData);
    }

    // Store message for receiver
    const receiverUser = users.find(u => u.username === to);
    if (receiverUser) {
      if (!receiverUser.privateMessages[senderUsername]) {
        receiverUser.privateMessages[senderUsername] = [];
      }
      receiverUser.privateMessages[senderUsername].push(messageData);
    }

    // Emit message to recipient if connected
    const receiverSocketId = Object.keys(connectedUsers).find(key => connectedUsers[key] === to);
    if (receiverSocketId) {
      io.to(receiverSocketId).emit('private message', { from: senderUsername, message: messageData });
    }
    // Also emit to sender for immediate display
    socket.emit('private message', { from: senderUsername, message: messageData });

    console.log(`Private message from ${senderUsername} to ${to}: ${message}`);
  });

  socket.on('get private messages', ({ withUser }, callback) => {
    const currentUser = socket.user.username;
    const user = users.find(u => u.username === currentUser);
    if (user && user.privateMessages[withUser]) {
      callback(user.privateMessages[withUser]);
    } else {
      callback([]);
    }
  });

  socket.on('chat message', (msg) => {
    const username = connectedUsers[socket.id] || 'Anonymous';
    const messageData = { username, message: msg, timestamp: new Date() };
    messages.push(messageData);
    // Keep message history to a reasonable size, e.g., last 100 messages
    if (messages.length > 100) {
      messages.shift();
    }
    io.emit('chat message', messageData);
    console.log(`${username}: ${msg}`);
  });

  socket.on('disconnect', () => {
    const username = connectedUsers[socket.id];
    if (username) {
      delete connectedUsers[socket.id];
      io.emit('user left', username);
      console.log(`${username} left the chat`);
    }
    console.log('user disconnected');
  });
});

server.listen(3000, () => {
  console.log('listening on *:3000');
});
