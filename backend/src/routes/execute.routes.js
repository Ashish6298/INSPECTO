const express = require('express');
const router = express.Router();
const { runRequest } = require('../controllers/execute.controller');

router.post('/', runRequest);

module.exports = router;