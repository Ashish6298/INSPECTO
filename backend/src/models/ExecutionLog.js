const mongoose = require('mongoose');

const ExecutionLogSchema = new mongoose.Schema({
  requestName: String,
  method: String,
  url: String,
  statusCode: Number,
  duration: Number, // in ms
  responseSize: Number, // in bytes
  timestamp: { type: Date, default: Date.now },
  success: Boolean
});

module.exports = mongoose.model('ExecutionLog', ExecutionLogSchema);