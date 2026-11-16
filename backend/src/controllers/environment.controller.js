const Environment = require('../models/Environment');

exports.createEnv = async (req, res) => {
  try {
    // Normalize variables if passed as an object/map
    let variables = req.body.variables;
    if (variables && !Array.isArray(variables) && typeof variables === 'object') {
      variables = Object.entries(variables).map(([key, value]) => ({
        key,
        value: String(value),
        enabled: true,
      }));
    }

    const env = await Environment.create({
      name: req.body.name,
      variables: variables || [],
      isActive: req.body.isActive || false,
    });
    res.status(201).json(env);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

exports.getEnvs = async (req, res) => {
  try {
    const envs = await Environment.find();
    res.json(envs);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

exports.getEnvById = async (req, res) => {
  try {
    const env = await Environment.findById(req.params.id);
    if (!env) {
      return res.status(404).json({ error: 'Environment not found' });
    }
    res.json(env);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

exports.updateEnv = async (req, res) => {
  try {
    let variables = req.body.variables;
    if (variables && !Array.isArray(variables) && typeof variables === 'object') {
      variables = Object.entries(variables).map(([key, value]) => ({
        key,
        value: String(value),
        enabled: true,
      }));
    }

    const updateData = {};
    if (req.body.name !== undefined) updateData.name = req.body.name;
    if (variables !== undefined) updateData.variables = variables;
    if (req.body.isActive !== undefined) updateData.isActive = req.body.isActive;

    const updatedEnv = await Environment.findByIdAndUpdate(
      req.params.id,
      updateData,
      { new: true, runValidators: true }
    );

    if (!updatedEnv) {
      return res.status(404).json({ error: 'Environment not found' });
    }

    res.status(200).json(updatedEnv);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

exports.deleteEnv = async (req, res) => {
  try {
    const env = await Environment.findByIdAndDelete(req.params.id);
    if (!env) {
      return res.status(404).json({ error: 'Environment not found' });
    }
    res.status(200).json({ message: 'Environment deleted' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

exports.activateEnv = async (req, res) => {
  try {
    // Reset all environments to inactive
    await Environment.updateMany({}, { isActive: false });

    // Set the target environment to active
    const activatedEnv = await Environment.findByIdAndUpdate(
      req.params.id,
      { isActive: true },
      { new: true }
    );

    if (!activatedEnv) {
      return res.status(404).json({ error: 'Environment not found' });
    }

    res.status(200).json(activatedEnv);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};
