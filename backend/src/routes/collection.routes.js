const express = require('express');
const router = express.Router();
const { createCollection, getCollections } = require('../controllers/collection.controller');

router.post('/', createCollection);
router.get('/', getCollections);

module.exports = router;