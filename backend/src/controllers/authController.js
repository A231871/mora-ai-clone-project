const User = require('../models/User');
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const { OAuth2Client } = require('google-auth-library');

const googleOAuthClient = new OAuth2Client();

// Register a new user
exports.register = async (req, res) => {
    try {
        const { username, password } = req.body;

        // Check if user exists
        const existingUser = await User.findOne({ username });
        if (existingUser) return res.status(400).json({ error: 'Username already taken!' });

        // Hash password
        const hashedPassword = await bcrypt.hash(password, 10);

        // Create user
        const newUser = new User({ username, password: hashedPassword });
        await newUser.save();

        res.status(201).json({ message: 'User registered successfully!' });
    } catch (error) {
        res.status(500).json({ error: 'Server error during registration.' });
    }
};

// Login user
exports.login = async (req, res) => {
    try {
        const { username, password } = req.body;

        // Find user
        const user = await User.findOne({ username });
        if (!user) return res.status(400).json({ error: 'User not found!' });

        if (!user.password) {
            return res.status(400).json({ error: 'This account uses Google sign-in.' });
        }

        const isMatch = await bcrypt.compare(password, user.password);
        if (!isMatch) return res.status(400).json({ error: 'Invalid credentials!' });

        // Generate Token
        const token = jwt.sign(
            { userId: user._id, username: user.username },
            process.env.JWT_SECRET,
            { expiresIn: '7d' }
        );

        res.status(200).json({ 
            message: 'Login successful!', 
            token,
            avatarConfig: user.avatarConfig 
        });
    } catch (error) {
        res.status(500).json({ error: 'Server error during login.' });
    }
};

exports.googleLogin = async (req, res) => {
    try {
        const { idToken } = req.body;
        if (!idToken) {
            return res.status(400).json({ error: 'idToken is required' });
        }

        const audience = process.env.GOOGLE_CLIENT_ID;
        if (!audience) {
            return res.status(503).json({ error: 'Google sign-in is not configured on the server.' });
        }

        const ticket = await googleOAuthClient.verifyIdToken({
            idToken,
            audience,
        });
        const payload = ticket.getPayload();
        if (!payload || !payload.sub) {
            return res.status(401).json({ error: 'Invalid Google token' });
        }

        const googleId = payload.sub;
        const email = (payload.email || '').trim();

        let user = await User.findOne({ googleId });
        if (!user) {
            let base = email && email.includes('@') ? email.split('@')[0] : `user_${googleId.slice(0, 8)}`;
            let username = base;
            let suffix = 0;
            while (await User.findOne({ username })) {
                suffix += 1;
                username = `${base}_${suffix}`;
            }

            user = await User.create({
                username,
                password: null,
                googleId,
            });
        }

        const token = jwt.sign(
            { userId: user._id, username: user.username },
            process.env.JWT_SECRET,
            { expiresIn: '7d' }
        );

        res.status(200).json({
            message: 'Login successful!',
            token,
            avatarConfig: user.avatarConfig,
        });
    } catch (error) {
        console.error('googleLogin:', error);
        res.status(401).json({ error: 'Google authentication failed' });
    }
};