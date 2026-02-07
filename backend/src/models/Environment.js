const mongoose = require('mongoose');

const EnvironmentSchema = new mongoose.Schema({
  name: { type: String, required: true },
  variables: [{
    key: String,
    value: String,
    enabled: { type: Boolean, default: true }
  }],
  isActive: { type: Boolean, default: false } // Tracks currently selected env
}, { timestamps: true });

module.exports = mongoose.model('Environment', EnvironmentSchema);