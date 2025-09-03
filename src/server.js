const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
const compression = require('compression');
require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 3000;

// Import routes
const wildlifeRoutes = require('./routes/wildlife');
const routeRoutes = require('./routes/routes');
const accommodationRoutes = require('./routes/accommodations');
const recommendationRoutes = require('./routes/recommendations');

// Middleware
app.use(helmet()); // Security headers
app.use(cors()); // Enable CORS for Flutter app
app.use(compression()); // Compress responses
app.use(morgan('combined')); // Logging
app.use(express.json({ limit: '10mb' })); // Parse JSON
app.use(express.urlencoded({ extended: true }));

// Health check endpoint
app.get('/health', (req, res) => {
  res.json({ 
    status: 'OK', 
    message: 'AI Safari Backend is running! 🦁',
    timestamp: new Date().toISOString(),
    version: '1.0.0'
  });
});

// API Routes
app.use('/api/wildlife', wildlifeRoutes);
app.use('/api/routes', routeRoutes);
app.use('/api/accommodations', accommodationRoutes);
app.use('/api/recommendations', recommendationRoutes);

// 404 handler
app.use('*', (req, res) => {
  res.status(404).json({ 
    error: 'Route not found',
    message: 'The requested endpoint does not exist'
  });
});

// Error handler
app.use((err, req, res, next) => {
  console.error('Error:', err);
  res.status(500).json({ 
    error: 'Internal server error',
    message: 'Something went wrong on our end'
  });
});

// Start server
app.listen(PORT, () => {
  console.log(`🚀 AI Safari Backend running on port ${PORT}`);
  console.log(`📱 Health check: http://localhost:${PORT}/health`);
  console.log(`🔗 API Base: http://localhost:${PORT}/api`);
});

module.exports = app;
