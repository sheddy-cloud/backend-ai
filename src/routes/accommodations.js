const express = require('express');
const router = express.Router();
const { getRows, getRow } = require('../database/config');

// Get all accommodations
router.get('/', async (req, res) => {
  try {
    console.log('🏨 Fetching all accommodations');

    const accommodations = await getRows(`
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
        a.image_url,
        a.created_at
      FROM accommodations a
      JOIN parks p ON a.park_id = p.park_id
      ORDER BY a.score DESC
    `);

    // Parse JSON fields
    const formattedAccommodations = accommodations.map(acc => ({
      ...acc,
      amenities: JSON.parse(acc.amenities || '[]'),
      rating: parseFloat(acc.rating),
      score: parseFloat(acc.score)
    }));

    res.json({
      success: true,
      data: formattedAccommodations,
      timestamp: new Date().toISOString()
    });

  } catch (error) {
    console.error('❌ Error fetching accommodations:', error);
    res.status(500).json({
      error: 'Internal server error',
      message: 'Failed to fetch accommodations'
    });
  }
});

// Get accommodations by park
router.get('/park/:parkId', async (req, res) => {
  try {
    const { parkId } = req.params;
    const { maxPrice, familyFriendly, minRating } = req.query;
    
    console.log(`🏨 Fetching accommodations for park: ${parkId}`);

    let query = `
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
        a.image_url,
        a.created_at
      FROM accommodations a
      JOIN parks p ON a.park_id = p.park_id
      WHERE a.park_id = $1
    `;

    const params = [parkId];
    let paramCount = 1;

    // Add filters
    if (maxPrice) {
      paramCount++;
      query += ` AND CAST(REPLACE(REPLACE(a.price, '$', ''), '/night', '') AS INTEGER) <= $${paramCount}`;
      params.push(parseInt(maxPrice));
    }

    if (familyFriendly === 'true') {
      paramCount++;
      query += ` AND a.family_friendly = $${paramCount}`;
      params.push(true);
    }

    if (minRating) {
      paramCount++;
      query += ` AND a.rating >= $${paramCount}`;
      params.push(parseFloat(minRating));
    }

    query += ' ORDER BY a.score DESC';

    const accommodations = await getRows(query, params);

    if (accommodations.length === 0) {
      return res.status(404).json({
        error: 'No accommodations found',
        message: `No accommodations available for park ${parkId} with the specified criteria`
      });
    }

    // Parse JSON fields
    const formattedAccommodations = accommodations.map(acc => ({
      ...acc,
      amenities: JSON.parse(acc.amenities || '[]'),
      rating: parseFloat(acc.rating),
      score: parseFloat(acc.score)
    }));

    res.json({
      success: true,
      data: formattedAccommodations,
      parkId: parkId,
      filters: {
        maxPrice: maxPrice || null,
        familyFriendly: familyFriendly || null,
        minRating: minRating || null
      },
      timestamp: new Date().toISOString()
    });

  } catch (error) {
    console.error('❌ Error fetching accommodations for park:', error);
    res.status(500).json({
      error: 'Internal server error',
      message: 'Failed to fetch accommodations for park'
    });
  }
});

// Get specific accommodation by ID
router.get('/:accommodationId', async (req, res) => {
  try {
    const { accommodationId } = req.params;
    
    console.log(`🏨 Fetching accommodation: ${accommodationId}`);

    const accommodation = await getRow(`
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
        a.image_url,
        a.created_at
      FROM accommodations a
      JOIN parks p ON a.park_id = p.park_id
      WHERE a.accommodation_id = $1
    `, [accommodationId]);

    if (!accommodation) {
      return res.status(404).json({
        error: 'Accommodation not found',
        message: `Accommodation with ID ${accommodationId} not found`
      });
    }

    // Parse JSON fields
    const formattedAccommodation = {
      ...accommodation,
      amenities: JSON.parse(accommodation.amenities || '[]'),
      rating: parseFloat(accommodation.rating),
      score: parseFloat(accommodation.score)
    };

    res.json({
      success: true,
      data: formattedAccommodation,
      timestamp: new Date().toISOString()
    });

  } catch (error) {
    console.error('❌ Error fetching accommodation:', error);
    res.status(500).json({
      error: 'Internal server error',
      message: 'Failed to fetch accommodation'
    });
  }
});

// Health check for accommodations
router.get('/health', (req, res) => {
  res.json({
    status: 'OK',
    message: 'Accommodations API is running! 🏨',
    timestamp: new Date().toISOString()
  });
});

module.exports = router;


