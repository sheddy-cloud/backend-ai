const express = require('express');
const router = express.Router();
const { getRows, getRow } = require('../database/config');

// Get wildlife predictions for a specific park
router.get('/predictions/:parkId', async (req, res) => {
  try {
    const { parkId } = req.params;
    const { date } = req.query;

    console.log(`🦁 Fetching wildlife predictions for ${parkId}`);

    // Try to get predictions from database
    try {
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

      if (predictions.length > 0) {
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

        return res.json({
          success: true,
          data: formattedPredictions,
          parkId: parkId,
          timestamp: new Date().toISOString()
        });
      }
    } catch (dbError) {
      console.log('📊 Database not available, using fallback data');
    }

    // Fallback data when database is not available
    const fallbackData = getFallbackPredictions(parkId);
    
    res.json({
      success: true,
      data: fallbackData,
      parkId: parkId,
      timestamp: new Date().toISOString(),
      source: 'fallback'
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

// Fallback data function
function getFallbackPredictions(parkId) {
  const predictions = {
    'serengeti': {
      'lions': {
        'probability': 0.85,
        'optimalTime': '06:00 - 09:00',
        'bestLocation': 'Central Serengeti Plains',
        'confidence': 0.92,
        'tips': 'Best viewed during early morning game drives'
      },
      'elephants': {
        'probability': 0.78,
        'optimalTime': '15:00 - 18:00',
        'bestLocation': 'Seronera River Valley',
        'confidence': 0.88,
        'tips': 'Look near water sources in the afternoon'
      },
      'wildebeest': {
        'probability': 0.95,
        'optimalTime': 'All day',
        'bestLocation': 'Migration routes (seasonal)',
        'confidence': 0.98,
        'tips': 'Migration peaks from July to October'
      }
    },
    'manyara': {
      'tree_lions': {
        'probability': 0.70,
        'optimalTime': '14:00 - 17:00',
        'bestLocation': 'Lake Manyara shores',
        'confidence': 0.80,
        'tips': 'Unique tree-climbing behavior in this park'
      },
      'elephants': {
        'probability': 0.90,
        'optimalTime': '06:00 - 09:00',
        'bestLocation': 'Lake Manyara shores',
        'confidence': 0.95,
        'tips': 'Excellent elephant viewing year-round'
      }
    },
    'mikumi': {
      'elephants': {
        'probability': 0.88,
        'optimalTime': '06:00 - 09:00',
        'bestLocation': 'Mkata Plains',
        'confidence': 0.92,
        'tips': 'Large herds frequently seen on the plains'
      },
      'zebras': {
        'probability': 0.95,
        'optimalTime': 'All day',
        'bestLocation': 'Mkata Plains',
        'confidence': 0.98,
        'tips': 'Abundant throughout the park'
      }
    },
    'gombe': {
      'chimpanzees': {
        'probability': 0.75,
        'optimalTime': '06:00 - 10:00',
        'bestLocation': 'Forest trails',
        'confidence': 0.85,
        'tips': 'Requires guided forest walks'
      }
    }
  };

  return predictions[parkId] || {
    'general_wildlife': {
      'probability': 0.70,
      'optimalTime': '06:00 - 10:00',
      'bestLocation': 'Throughout the park',
      'confidence': 0.80,
      'tips': 'Wildlife viewing is best during early morning and late afternoon'
    }
  };
}

module.exports = router;


