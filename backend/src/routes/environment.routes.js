const express = require('express');
const router = express.Router();
const {
  createEnv,
  getEnvs,
  getEnvById,
  updateEnv,
  deleteEnv,
  activateEnv,
} = require('../controllers/environment.controller');

router.post('/', createEnv);
router.get('/', getEnvs);
router.get('/:id', getEnvById);
router.put('/:id', updateEnv);
router.delete('/:id', deleteEnv);
router.patch('/:id/activate', activateEnv);

module.exports = router;
