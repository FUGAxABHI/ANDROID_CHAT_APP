const multer = require('multer');
const path = require('path');
const logger = require('../utils/logger'); // Import logger

const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    cb(null, 'uploads/'); // Files will be saved in the 'uploads/' directory
  },
  filename: (req, file, cb) => {
    const filename = `${file.fieldname}-${Date.now()}${path.extname(file.originalname)}`;
    logger.info(`Saving file as: ${filename}`);
    cb(null, filename);
  },
});

const upload = multer({
  storage: storage,
  limits: { fileSize: 1024 * 1024 * 5 }, // 5MB limit
  fileFilter: (req, file, cb) => {
    logger.info(`File filter check for: ${file.originalname}`);
    logger.info(`Mimetype: ${file.mimetype}`);
    const filetypes = /jpeg|jpg|png|gif/;
    const extname = filetypes.test(path.extname(file.originalname).toLowerCase());
    const mimetype = filetypes.test(file.mimetype) || file.mimetype === 'application/octet-stream';

    if (mimetype && extname) {
      logger.info(`File accepted: ${file.originalname}`);
      return cb(null, true);
    } else {
      logger.error(`File rejected: ${file.originalname}. Only image files are allowed.`);
      cb(new Error('Error: Images Only!'));
    }
  },
});

module.exports = upload;
