const express = require('express');

const {
  clearHistory,
  getChatHistory,
  sendMessage,
} = require('../controllers/chatController');
const { protect } = require('../middlewares/authMiddleware');

const router = express.Router();

router.use(protect);

router.get('/messages', getChatHistory);
router.delete('/messages', clearHistory);
router.post('/send', sendMessage);

module.exports = router;
