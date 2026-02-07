const Collection = require('../models/Collection');

exports.createCollection = async (req, res) => {
  try {
    const collection = await Collection.create(req.body);
    res.status(201).json(collection);
  } catch (err) { res.status(500).json({ error: err.message }); }
};

exports.getCollections = async (req, res) => {
  try {
    const collections = await Collection.find().populate('requests');
    res.json(collections);
  } catch (err) { res.status(500).json({ error: err.message }); }
};