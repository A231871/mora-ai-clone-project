const mongoose = require('mongoose');

const userSchema = new mongoose.Schema({
    username: { type: String, required: true, unique: true },
    email: { type: String, lowercase: true, trim: true, unique: true, sparse: true },
    password: { type: String, required: false },
    googleId: { type: String, unique: true, sparse: true },
    systemRole: {
        type: String,
        enum: ['admin', 'member'],
        default: 'member'
    },
    profile: {
        displayName: { type: String, default: '' },
        bio: { type: String, default: '' }
    },
    avatarAssetId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'FileAsset',
        default: null
    },
    avatarConfig: {
        hair: { type: String, default: 'default_hair' },
        face: { type: String, default: 'default_face' },
        outfit: { type: String, default: 'default_outfit' },
        color: { type: String, default: 'blue_neon' }
    },
    lastLoginAt: {
        type: Date,
        default: null
    }
}, { timestamps: true });

module.exports = mongoose.model('User', userSchema);
