const mongoose = require('mongoose');

const userSchema = new mongoose.Schema({
    username: { type: String, required: true, unique: true },
    password: { type: String, required: true },
    // This will store the active PNG layers for the 2D model
    avatarConfig: {
        hair: { type: String, default: 'default_hair' },
        face: { type: String, default: 'default_face' },
        outfit: { type: String, default: 'default_outfit' },
        color: { type: String, default: 'blue_neon' }
    }
}, { timestamps: true });

module.exports = mongoose.model('User', userSchema);