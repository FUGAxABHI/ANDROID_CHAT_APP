const User = require('../models/User');
const CryptoJS = require('crypto-js');
const jwt = require('jsonwebtoken');
const logger = require('../utils/logger');
const util = require('util');

const signJwt = util.promisify(jwt.sign);

exports.register = async (req, res) => {
  const { username, password } = req.body;

  try {
    logger.debug(`[Register] Start registration for user: ${username}`);
    logger.debug(`[Register] Step 1: Checking if user ${username} exists.`);
    let user = await User.findOne({ username });
    logger.debug(`[Register] Step 1 Result: User.findOne returned ${user ? 'found' : 'not found'}.`);
    if (user) {
      logger.debug(`[Register] User ${username} already exists. Returning 400.`);
      return res.status(400).json({ message: 'User already exists' });
    }

    logger.debug(`[Register] Step 2: Creating new User instance for: ${username}`);
    user = new User({
      username,
      password,
    });
    logger.debug(`[Register] Step 2 Result: New User instance created: ${user ? 'success' : 'failure'}.`);

    logger.debug(`[Register] Step 3: Hashing password for user: ${username}`);
    user.password = CryptoJS.SHA256(password).toString();
    logger.debug(`[Register] Step 3 Result: Password hashed.`);

    logger.info(`[Register] --- PROOF POINT 1: Backend received registration request for user: ${username}. About to save to database...`);
    await user.save();
    logger.info(`[Register] --- PROOF POINT 2: Successfully saved user to database.`);

    logger.debug(`[Register] Step 5: Generating JWT payload for user: ${username}`);
    const payload = {
      id: user.id,
      username: user.username,
    };
    logger.debug(`[Register] Step 5 Result: Payload created.`);

    logger.debug(`[Register] Step 6: Signing JWT token for user: ${username}`);
    const token = await signJwt(payload, process.env.JWT_SECRET, { expiresIn: '30d' });
    logger.debug(`[Register] Step 6 Result: JWT token signed. Sending 201 response.`);
    res.status(201).json({ token });
  } catch (err) {
    logger.error('[Register] Server error during registration:', err.message, err.stack);
    res.status(500).json({ message: 'Server error', error: err.message, stack: err.stack });
  }
};

exports.login = async (req, res) => {
  const { username, password } = req.body;
  logger.info(`[Login] Attempting login for user: ${username}`);

  try {
    logger.debug(`[Login] Step 1: Finding user '${username}' in the database.`);
    let user = await User.findOne({ username });
    if (!user) {
      logger.warn(`[Login] Auth failed: User '${username}' not found.`);
      return res.status(400).json({ message: 'Invalid credentials' });
    }
    logger.debug(`[Login] Step 1 Result: User found. User ID: ${user._id}`);

    logger.debug(`[Login] Step 2: Comparing password for user '${username}'.`);
    const isMatch = CryptoJS.SHA256(password).toString() === user.password;
    logger.debug(`[Login] Step 2 Result: Password match: ${isMatch}`);

    if (!isMatch) {
      logger.warn(`[Login] Auth failed: Invalid password for user '${username}'.`);
      return res.status(400).json({ message: 'Invalid credentials' });
    }

    logger.debug(`[Login] Step 3: Generating JWT for user '${username}'.`);
    const token = jwt.sign({ id: user._id, username: user.username }, process.env.JWT_SECRET, { expiresIn: '30d' });
    logger.info(`[Login] Successfully generated JWT for user '${username}'.`);

    res.json({ token });
  } catch (error) {
    logger.error(`[Login] Server error during login for user '${username}':`, error.message, error.stack);
    res.status(500).json({ message: 'Server error', error: error.message });
  }
};