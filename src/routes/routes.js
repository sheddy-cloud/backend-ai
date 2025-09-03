const express = require('express');
const router = express.Router();
const { getRows, getRow } = require('../database/config');

// Get all safari routes
router.get('/', async (req, res) => {
  try {
    console.log('🗺️ Fetching all safari routes');

    const routes = await getRows(`
      SELECT 
        route_id,
        name,
        description,
        duration,
        difficulty,
        best_time,
        estimated_cost,
        transportation,
        accommodation_type,
        score,
        highlights,
        parks_included,
        created_at
      FROM safari_routes
      ORDER BY score DESC
    `);

    // Parse JSON fields
    const formattedRoutes = routes.map(route => ({
      ...route,
      highlights: JSON.parse(route.highlights || '[]'),
      parks_included: JSON.parse(route.parks_included || '[]'),
      score: parseFloat(route.score)
    }));

    res.json({
      success: true,
      data: formattedRoutes,
      timestamp: new Date().toISOString()
    });

  } catch (error) {
    console.error('❌ Error fetching safari routes:', error);
    res.status(500).json({
      error: 'Internal server error',
      message: 'Failed to fetch safari routes'
    });
  }
});

// Get specific route by ID
router.get('/:routeId', async (req, res) => {
  try {
    const { routeId } = req.params;
    
    console.log(`🗺️ Fetching route: ${routeId}`);

    const route = await getRow(`
      SELECT 
        route_id,
        name,
        description,
        duration,
        difficulty,
        best_time,
        estimated_cost,
        transportation,
        accommodation_type,
        score,
        highlights,
        parks_included,
        created_at
      FROM safari_routes
      WHERE route_id = $1
    `, [routeId]);

    if (!route) {
      return res.status(404).json({
        error: 'Route not found',
        message: `Route with ID ${routeId} not found`
      });
    }

    // Parse JSON fields
    const formattedRoute = {
      ...route,
      highlights: JSON.parse(route.highlights || '[]'),
      parks_included: JSON.parse(route.parks_included || '[]'),
      score: parseFloat(route.score)
    };

    res.json({
      success: true,
      data: formattedRoute,
      timestamp: new Date().toISOString()
    });

  } catch (error) {
    console.error('❌ Error fetching route:', error);
    res.status(500).json({
      error: 'Internal server error',
      message: 'Failed to fetch route'
    });
  }
});

// Get routes by park
router.get('/park/:parkId', async (req, res) => {
  try {
    const { parkId } = req.params;
    
    console.log(`🗺️ Fetching routes for park: ${parkId}`);

    const routes = await getRows(`
      SELECT 
        route_id,
        name,
        description,
        duration,
        difficulty,
        best_time,
        estimated_cost,
        transportation,
        accommodation_type,
        score,
        highlights,
        parks_included,
        created_at
      FROM safari_routes
      WHERE parks_included @> $1
      ORDER BY score DESC
    `, [JSON.stringify([parkId])]);

    if (routes.length === 0) {
      return res.status(404).json({
        error: 'No routes found',
        message: `No routes available for park ${parkId}`
      });
    }

    // Parse JSON fields
    const formattedRoutes = routes.map(route => ({
      ...route,
      highlights: JSON.parse(route.highlights || '[]'),
      parks_included: JSON.parse(route.parks_included || '[]'),
      score: parseFloat(route.score)
    }));

    res.json({
      success: true,
      data: formattedRoutes,
      parkId: parkId,
      timestamp: new Date().toISOString()
    });

  } catch (error) {
    console.error('❌ Error fetching routes for park:', error);
    res.status(500).json({
      error: 'Internal server error',
      message: 'Failed to fetch routes for park'
    });
  }
});

// Health check for routes
router.get('/health', (req, res) => {
  res.json({
    status: 'OK',
    message: 'Routes API is running! 🗺️',
    timestamp: new Date().toISOString()
  });
});

module.exports = router;

