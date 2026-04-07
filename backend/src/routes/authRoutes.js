const express = require('express');
const router = express.Router();
const {
  register,
  login,
  googleLogin,
  refresh,
  logout,
  logoutAll,
  me,
} = require('../controllers/authController');
const { protect } = require('../middlewares/authMiddleware');

router.post('/register', register);
router.post('/login', login);
router.post('/google', googleLogin);
router.post('/refresh', refresh);
router.post('/logout', protect, logout);
router.post('/logout-all', protect, logoutAll);
router.get('/me', protect, me);

module.exports = router;
