const express = require('express');
const router = express.Router();
const { createEnv, getEnvs } = require('../controllers/environment.controller');

router.post('/', createEnv);
router.get('/', getEnvs);

module.exports = router;