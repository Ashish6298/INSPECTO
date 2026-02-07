const { executeRequest } = require('../services/requestExecutor.service');
const Environment = require('../models/Environment');

exports.runRequest = async (req, res) => {
  try {
    const { request, environmentId } = req.body;
    
    let environment = null;
    if (environmentId) {
      environment = await Environment.findById(environmentId);
    }

    const result = await executeRequest(request, environment);
    res.json(result);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};