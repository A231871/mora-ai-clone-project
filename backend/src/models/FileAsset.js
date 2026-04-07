const mongoose = require('mongoose');

const fileAssetSchema = new mongoose.Schema(
  {
    uploadedBy: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
      index: true,
    },
    ownerType: {
      type: String,
      enum: ['user', 'project', 'task', 'comment', 'reminder', 'unassigned'],
      default: 'unassigned',
      index: true,
    },
    ownerId: {
      type: mongoose.Schema.Types.ObjectId,
      default: null,
      index: true,
    },
    taskIds: [
      {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Task',
        index: true,
      },
    ],
    kind: {
      type: String,
      enum: ['image', 'pdf', 'doc', 'docx'],
      required: true,
      index: true,
    },
    originalName: {
      type: String,
      required: true,
      trim: true,
    },
    storedName: {
      type: String,
      required: true,
      trim: true,
    },
    mimeType: {
      type: String,
      required: true,
      trim: true,
    },
    size: {
      type: Number,
      required: true,
      min: 0,
    },
    storagePath: {
      type: String,
      required: true,
      trim: true,
    },
    publicUrl: {
      type: String,
      required: true,
      trim: true,
    },
    attachedAt: {
      type: Date,
      default: null,
    },
  },
  { timestamps: true },
);

module.exports = mongoose.model('FileAsset', fileAssetSchema);
