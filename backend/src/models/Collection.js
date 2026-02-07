const mongoose = require('mongoose');

const CollectionSchema = new mongoose.Schema({
  name: { type: String, required: true },
  description: String,
  folders: [{
    name: String,
    requests: [{ type: mongoose.Schema.Types.ObjectId, ref: 'ApiRequest' }]
  }],
  requests: [{ type: mongoose.Schema.Types.ObjectId, ref: 'ApiRequest' }] // Root level requests
}, { timestamps: true });

module.exports = mongoose.model('Collection', CollectionSchema);