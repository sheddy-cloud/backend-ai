const express = require('express');
const router = express.Router();
const { getRows, getRow } = require('../database/config');

// Get personalized recommendations
router.post('/personalized', async (req, res) => {
  try {
    const { userProfile, context } = req.body;
    
    console.log('🧠 Generating personalized recommendations');

    if (!userProfile) {
      return res.status(400).json({
        error: 'Missing user profile',
        message: 'User profile is required for personalized recommendations'
      });
    }

    // Extract user preferences
    const preferences = userProfile.preferences || {};
    const userHistory = userProfile.history || [];

    // Analyze user preferences and generate recommendations
    const recommendations = {
      wildlifeFocus: preferences.wildlifePhotography === true ? 'High' : 'Moderate',
      budgetLevel: preferences.budgetLevel || 'Mid-Range',
      travelStyle: preferences.travelStyle || 'Adventure',
      groupSize: preferences.groupSize || 'Couple',
      experienceLevel: preferences.safariExperience || 'Beginner',
    };

    // Get wildlife recommendations based on preferences
    let wildlifeQuery = `
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
    `;

    // Filter by experience level
    if (preferences.safariExperience === 'Beginner') {
      wildlifeQuery += ` WHERE wp.probability >= 0.8`;
    } else if (preferences.safariExperience === 'Intermediate') {
      wildlifeQuery += ` WHERE wp.probability >= 0.6`;
    }

    wildlifeQuery += ` ORDER BY wp.probability DESC LIMIT 20`;

    const wildlifeRecommendations = await getRows(wildlifeQuery);

    // Get route recommendations
    let routeQuery = `
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
        parks_included
      FROM safari_routes
    `;

    // Filter routes by difficulty based on experience
    if (preferences.safariExperience === 'Beginner') {
      routeQuery += ` WHERE difficulty = 'Easy'`;
    } else if (preferences.safariExperience === 'Intermediate') {
      routeQuery += ` WHERE difficulty IN ('Easy', 'Moderate')`;
    }

    routeQuery += ` ORDER BY score DESC LIMIT 10`;

    const routeRecommendations = await getRows(routeQuery);

    // Get accommodation recommendations
    let accommodationQuery = `
      SELECT 
        a.accommodation_id,
        a.park_id,
        p.name as park_name,
        a.name,
        a.type,
        a.rating,
        a.price,
        a.amenities,
        a.location,
        a.wildlife_viewing,
        a.photography_rating,
        a.family_friendly,
        a.score,
        a.image_url
      FROM accommodations a
      JOIN parks p ON a.park_id = p.park_id
    `;

    // Filter by budget and family preferences
    if (preferences.budgetLevel === 'Budget') {
      accommodationQuery += ` WHERE CAST(REPLACE(REPLACE(a.price, '$', ''), '/night', '') AS INTEGER) <= 300`;
    } else if (preferences.budgetLevel === 'Mid-Range') {
      accommodationQuery += ` WHERE CAST(REPLACE(REPLACE(a.price, '$', ''), '/night', '') AS INTEGER) <= 600`;
    }

    if (preferences.groupSize === 'Family') {
      accommodationQuery += accommodationQuery.includes('WHERE') ? ` AND a.family_friendly = true` : ` WHERE a.family_friendly = true`;
    }

    accommodationQuery += ` ORDER BY a.score DESC LIMIT 15`;

    const accommodationRecommendations = await getRows(accommodationQuery);

    // Format responses
    const formattedWildlife = wildlifeRecommendations.map(w => ({
      parkId: w.park_id,
      parkName: w.park_name,
      animalType: w.animal_type,
      probability: parseFloat(w.probability),
      optimalTime: w.optimal_time,
      bestLocation: w.best_location,
      confidence: parseFloat(w.confidence),
      tips: w.tips
    }));

    const formattedRoutes = routeRecommendations.map(r => ({
      ...r,
      highlights: JSON.parse(r.highlights || '[]'),
      parks_included: JSON.parse(r.parks_included || '[]'),
      score: parseFloat(r.score)
    }));

    const formattedAccommodations = accommodationRecommendations.map(a => ({
      ...a,
      amenities: JSON.parse(a.amenities || '[]'),
      rating: parseFloat(a.rating),
      score: parseFloat(a.score)
    }));

    res.json({
      success: true,
      data: {
        personalizedInsights: recommendations,
        wildlifeRecommendations: formattedWildlife,
        routeRecommendations: formattedRoutes,
        accommodationRecommendations: formattedAccommodations,
        generatedAt: new Date().toISOString(),
        confidence: 0.85,
        userProfile: userProfile,
        context: context
      },
      timestamp: new Date().toISOString()
    });

  } catch (error) {
    console.error('❌ Error generating personalized recommendations:', error);
    res.status(500).json({
      error: 'Internal server error',
      message: 'Failed to generate personalized recommendations'
    });
  }
});

// Get quick recommendations for a park
router.get('/park/:parkId/quick', async (req, res) => {
  try {
    const { parkId } = req.params;
    
    console.log(`🧠 Generating quick recommendations for park: ${parkId}`);

    // Get top wildlife predictions
    const wildlife = await getRows(`
      SELECT 
        animal_type,
        probability,
        optimal_time,
        best_location,
        confidence,
        tips
      FROM wildlife_predictions 
      WHERE park_id = $1
      ORDER BY probability DESC
      LIMIT 5
    `, [parkId]);

    // Get top accommodations
    const accommodations = await getRows(`
      SELECT 
        accommodation_id,
        name,
        type,
        rating,
        price,
        score,
        image_url
      FROM accommodations
      WHERE park_id = $1
      ORDER BY score DESC
      LIMIT 3
    `, [parkId]);

    // Get routes including this park
    const routes = await getRows(`
      SELECT 
        route_id,
        name,
        duration,
        difficulty,
        score
      FROM safari_routes
      WHERE parks_included @> $1
      ORDER BY score DESC
      LIMIT 3
    `, [JSON.stringify([parkId])]);

    res.json({
      success: true,
      data: {
        parkId: parkId,
        wildlife: wildlife.map(w => ({
          ...w,
          probability: parseFloat(w.probability),
          confidence: parseFloat(w.confidence)
        })),
        accommodations: accommodations.map(a => ({
          ...a,
          rating: parseFloat(a.rating),
          score: parseFloat(a.score)
        })),
        routes: routes.map(r => ({
          ...r,
          score: parseFloat(r.score)
        }))
      },
      timestamp: new Date().toISOString()
    });

  } catch (error) {
    console.error('❌ Error generating quick recommendations:', error);
    res.status(500).json({
      error: 'Internal server error',
      message: 'Failed to generate quick recommendations'
    });
  }
});

// Health check for recommendations
router.get('/health', (req, res) => {
  res.json({
    status: 'OK',
    message: 'Recommendations API is running! 🧠',
    timestamp: new Date().toISOString()
  });
});

module.exports = router;

