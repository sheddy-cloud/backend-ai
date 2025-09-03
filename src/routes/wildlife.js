const express = require('express');
const router = express.Router();
const { getRows, getRow } = require('../database/config');

// Get wildlife predictions for a specific park
router.get('/predictions/:parkId', async (req, res) => {
  try {
    const { parkId } = req.params;
    const { date } = req.query;

    console.log(`🦁 Fetching wildlife predictions for ${parkId}`);

    // Get wildlife predictions from database
    const predictions = await getRows(`
      SELECT 
        animal_type,
        probability,
        optimal_time,
        best_location,
        confidence,
        tips,
        prediction_date
      FROM wildlife_predictions 
      WHERE park_id = $1
      ORDER BY probability DESC
    `, [parkId]);

    if (predictions.length === 0) {
      return res.status(404).json({
        error: 'No predictions found',
        message: `No wildlife predictions available for ${parkId}`
      });
    }

    // Format response to match your Flutter app structure
    const formattedPredictions = {};
    predictions.forEach(prediction => {
      formattedPredictions[prediction.animal_type] = {
        probability: parseFloat(prediction.probability),
        optimalTime: prediction.optimal_time,
        bestLocation: prediction.best_location,
        confidence: parseFloat(prediction.confidence),
        tips: prediction.tips
      };
    });

    res.json({
      success: true,
      data: formattedPredictions,
      parkId: parkId,
      timestamp: new Date().toISOString()
    });

  } catch (error) {
    console.error('❌ Error fetching wildlife predictions:', error);
    res.status(500).json({
      error: 'Internal server error',
      message: 'Failed to fetch wildlife predictions'
    });
  }
});

// Get all wildlife predictions
router.get('/predictions', async (req, res) => {
  try {
    console.log('🦁 Fetching all wildlife predictions');

    const predictions = await getRows(`
      SELECT 
        wp.park_id,
        p.name as park_name,
        wp.animal_type,
        wp.probability,
        wp.optimal_time,
        wp.best_location,
        wp.confidence,
        wp.tips
      FROM wildlife_predictions wp
      JOIN parks p ON wp.park_id = p.park_id
      ORDER BY wp.park_id, wp.probability DESC
    `);

    // Group by park
    const groupedPredictions = {};
    predictions.forEach(prediction => {
      if (!groupedPredictions[prediction.park_id]) {
        groupedPredictions[prediction.park_id] = {
          parkName: prediction.park_name,
          predictions: {}
        };
      }
      
      groupedPredictions[prediction.park_id].predictions[prediction.animal_type] = {
        probability: parseFloat(prediction.probability),
        optimalTime: prediction.optimal_time,
        bestLocation: prediction.best_location,
        confidence: parseFloat(prediction.confidence),
        tips: prediction.tips
      };
    });

    res.json({
      success: true,
      data: groupedPredictions,
      timestamp: new Date().toISOString()
    });

  } catch (error) {
    console.error('❌ Error fetching all wildlife predictions:', error);
    res.status(500).json({
      error: 'Internal server error',
      message: 'Failed to fetch wildlife predictions'
    });
  }
});

// Get specific animal prediction across all parks
router.get('/animal/:animalType', async (req, res) => {
  try {
    const { animalType } = req.params;
    
    console.log(`🦁 Fetching ${animalType} predictions across all parks`);

    const predictions = await getRows(`
      SELECT 
        wp.park_id,
        p.name as park_name,
        wp.probability,
        wp.optimal_time,
        wp.best_location,
        wp.confidence,
        wp.tips
      FROM wildlife_predictions wp
      JOIN parks p ON wp.park_id = p.park_id
      WHERE wp.animal_type = $1
      ORDER BY wp.probability DESC
    `, [animalType]);

    if (predictions.length === 0) {
      return res.status(404).json({
        error: 'No predictions found',
        message: `No predictions available for ${animalType}`
      });
    }

    res.json({
      success: true,
      data: {
        animalType: animalType,
        predictions: predictions.map(p => ({
          parkId: p.park_id,
          parkName: p.park_name,
          probability: parseFloat(p.probability),
          optimalTime: p.optimal_time,
          bestLocation: p.best_location,
          confidence: parseFloat(p.confidence),
          tips: p.tips
        }))
      },
      timestamp: new Date().toISOString()
    });

  } catch (error) {
    console.error('❌ Error fetching animal predictions:', error);
    res.status(500).json({
      error: 'Internal server error',
      message: 'Failed to fetch animal predictions'
    });
  }
});

// Health check for wildlife routes
router.get('/health', (req, res) => {
  res.json({
    status: 'OK',
    message: 'Wildlife API is running! 🦁',
    timestamp: new Date().toISOString()
  });
});

module.exports = router;

