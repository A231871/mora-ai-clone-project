const mongoose = require('mongoose');

const userSchema = new mongoose.Schema({
    username: { type: String, required: true, unique: true },
    password: { type: String, required: false },
    googleId: { type: String, unique: true, sparse: true },
    avatarConfig: {
        hair: { type: String, default: 'default_hair' },
        face: { type: String, default: 'default_face' },
        outfit: { type: String, default: 'default_outfit' },
        color: { type: String, default: 'blue_neon' }
    }
}, { timestamps: true });

module.exports = mongoose.model('User', userSchema);
