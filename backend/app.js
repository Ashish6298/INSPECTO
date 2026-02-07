const express = require('express');
const cors = require('cors');
const morgan = require('morgan');

const executeRoutes = require('./src/routes/execute.routes');
const collectionRoutes = require('./src/routes/collection.routes');
const environmentRoutes = require('./src/routes/environment.routes');

const app = express();

// Middleware
app.use(cors());
app.use(express.json());
app.use(morgan('dev'));

// Routes
app.use('/api/execute', executeRoutes);
app.use('/api/collections', collectionRoutes);
app.use('/api/environments', environmentRoutes);

app.get('/', (req, res) => res.send('API Testing Tool Backend Running'));

module.exports = app;