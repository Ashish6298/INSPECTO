const mongoose = require('mongoose');

const ApiRequestSchema = new mongoose.Schema({
  name: { type: String, required: true },
  method: { 
    type: String, 
    required: true, 
    enum: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'HEAD', 'OPTIONS'] 
  },
  url: { type: String, required: true },
  headers: [{ key: String, value: String, enabled: Boolean }],
  params: [{ key: String, value: String, enabled: Boolean }],
  body: {
    type: { type: String, enum: ['none', 'json', 'text', 'form-data'], default: 'none' },
    content: mongoose.Schema.Types.Mixed // JSON string or object
  },
  collectionId: { type: mongoose.Schema.Types.ObjectId, ref: 'Collection' },
  folderId: String // Optional ID if nested in a folder
}, { timestamps: true });

module.exports = mongoose.model('ApiRequest', ApiRequestSchema);