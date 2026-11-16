const express = require('express');
const router = express.Router();
const {
  createCollection,
  getCollections,
  getCollectionById,
  addRequestToCollection,
  deleteCollection,
  deleteRequestFromCollection,
} = require('../controllers/collection.controller');

router.post('/', createCollection);
router.get('/', getCollections);
router.get('/:id', getCollectionById);
router.delete('/:id', deleteCollection);
router.post('/:id/requests', addRequestToCollection);
router.delete('/:id/requests/:requestId', deleteRequestFromCollection);

module.exports = router;
