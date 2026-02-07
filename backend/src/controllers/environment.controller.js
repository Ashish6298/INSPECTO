const Environment = require('../models/Environment');

exports.createEnv = async (req, res) => {
  try {
    const env = await Environment.create(req.body);
    res.status(201).json(env);
  } catch (err) { res.status(500).json({ error: err.message }); }
};

exports.getEnvs = async (req, res) => {
  try {
    const envs = await Environment.find();
    res.json(envs);
  } catch (err) { res.status(500).json({ error: err.message }); }
};