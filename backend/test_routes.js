const assert = require('assert');
const express = require('express');
const collectionRoutes = require('./src/routes/collection.routes');
const environmentRoutes = require('./src/routes/environment.routes');

console.log('=== VERIFYING ROUTE DEFINITIONS ===');

const getRoutePaths = (router) => {
  const routes = [];
  router.stack.forEach((layer) => {
    if (layer.route) {
      const methods = Object.keys(layer.route.methods).join(',').toUpperCase();
      routes.push(`${methods} ${layer.route.path}`);
    }
  });
  return routes;
};

const colRoutes = getRoutePaths(collectionRoutes);
console.log('Collection Routes:', colRoutes);
assert(colRoutes.includes('POST /'), 'POST / missing in collections');
assert(colRoutes.includes('GET /'), 'GET / missing in collections');
assert(colRoutes.includes('GET /:id'), 'GET /:id missing in collections');
assert(colRoutes.includes('DELETE /:id'), 'DELETE /:id missing in collections');
assert(colRoutes.includes('POST /:id/requests'), 'POST /:id/requests missing in collections');
assert(colRoutes.includes('DELETE /:id/requests/:requestId'), 'DELETE /:id/requests/:requestId missing in collections');
console.log('✓ All 6 Collection routes verified');

const envRoutes = getRoutePaths(environmentRoutes);
console.log('Environment Routes:', envRoutes);
assert(envRoutes.includes('POST /'), 'POST / missing in environments');
assert(envRoutes.includes('GET /'), 'GET / missing in environments');
assert(envRoutes.includes('GET /:id'), 'GET /:id missing in environments');
assert(envRoutes.includes('PUT /:id'), 'PUT /:id missing in environments');
assert(envRoutes.includes('DELETE /:id'), 'DELETE /:id missing in environments');
assert(envRoutes.includes('PATCH /:id/activate'), 'PATCH /:id/activate missing in environments');
console.log('✓ All 6 Environment routes verified');

console.log('=== ROUTE VERIFICATION COMPLETED (ALL 12 ROUTES PRESENT) ===');
