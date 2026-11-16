const Collection = require('../models/Collection');
const ApiRequest = require('../models/ApiRequest');

exports.createCollection = async (req, res) => {
  try {
    const collection = await Collection.create(req.body);
    res.status(201).json(collection);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

exports.getCollections = async (req, res) => {
  try {
    const collections = await Collection.find().populate('requests');
    res.json(collections);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

exports.getCollectionById = async (req, res) => {
  try {
    const collection = await Collection.findById(req.params.id).populate('requests');
    if (!collection) {
      return res.status(404).json({ error: 'Collection not found' });
    }
    res.json(collection);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

exports.addRequestToCollection = async (req, res) => {
  try {
    const collection = await Collection.findById(req.params.id);
    if (!collection) {
      return res.status(404).json({ error: 'Collection not found' });
    }

    // Normalize headers if provided as Map/Object
    let headers = req.body.headers;
    if (headers && !Array.isArray(headers) && typeof headers === 'object') {
      headers = Object.entries(headers).map(([key, value]) => ({
        key,
        value: String(value),
        enabled: true,
      }));
    }

    // Normalize params if provided as Map/Object
    let params = req.body.params;
    if (params && !Array.isArray(params) && typeof params === 'object') {
      params = Object.entries(params).map(([key, value]) => ({
        key,
        value: String(value),
        enabled: true,
      }));
    }

    // Normalize body
    let body = req.body.body;
    if (typeof body === 'string' || body === null || body === undefined) {
      body = {
        type: req.body.bodyType || 'none',
        content: body,
      };
    }

    const apiRequestData = {
      name: req.body.name || req.body.url || 'Untitled Request',
      method: req.body.method || 'GET',
      url: req.body.url,
      headers: headers || [],
      params: params || [],
      body: body,
      collectionId: collection._id,
      folderId: req.body.folderId || null,
    };

    const apiRequest = await ApiRequest.create(apiRequestData);
    collection.requests.push(apiRequest._id);
    await collection.save();

    res.status(201).json(apiRequest);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

exports.deleteCollection = async (req, res) => {
  try {
    const collection = await Collection.findById(req.params.id);
    if (!collection) {
      return res.status(404).json({ error: 'Collection not found' });
    }

    // Remove all associated ApiRequest documents
    await ApiRequest.deleteMany({ collectionId: collection._id });
    await Collection.findByIdAndDelete(collection._id);

    res.status(200).json({ message: 'Collection and associated requests deleted successfully' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

exports.deleteRequestFromCollection = async (req, res) => {
  try {
    const { id, requestId } = req.params;
    const collection = await Collection.findById(id);
    if (!collection) {
      return res.status(404).json({ error: 'Collection not found' });
    }

    // Remove requestId from collection requests array
    collection.requests = collection.requests.filter(
      rId => rId.toString() !== requestId
    );
    await collection.save();

    // Delete the ApiRequest document
    await ApiRequest.findByIdAndDelete(requestId);

    res.status(200).json({ message: 'Request removed from collection' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};
