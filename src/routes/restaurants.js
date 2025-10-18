const express = require('express');
const { protect, authorize } = require('../middleware/auth');
const { query, insert, update, delete: deleteRecord } = require('../config/database');

const router = express.Router();

// @desc    Get all restaurants
// @route   GET /api/restaurants
// @access  Public
router.get('/', async (req, res) => {
  try {
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 10;
    const offset = (page - 1) * limit;
    const { park, location, cuisine, priceRange } = req.query;

    let whereClause = 'is_active = $1';
    let params = [true];
    let paramCount = 1;

    if (park) {
      paramCount++;
      whereClause += ` AND park_id = $${paramCount}`;
      params.push(park);
    }

    if (location) {
      paramCount++;
      whereClause += ` AND location ILIKE $${paramCount}`;
      params.push(`%${location}%`);
    }

    if (cuisine) {
      paramCount++;
      whereClause += ` AND cuisine_type = $${paramCount}`;
      params.push(cuisine);
    }

    if (priceRange) {
      const [min, max] = priceRange.split('-').map(Number);
      if (min) {
        paramCount++;
        whereClause += ` AND price_range >= $${paramCount}`;
        params.push(min);
      }
      if (max) {
        paramCount++;
        whereClause += ` AND price_range <= $${paramCount}`;
        params.push(max);
      }
    }

    const restaurants = await query(
      'restaurants',
      where: whereClause,
      whereArgs: params,
      orderBy: 'rating DESC, created_at DESC',
      limit: limit,
      offset: offset
    );

    const totalResult = await query(
      'restaurants',
      where: whereClause,
      whereArgs: params
    );

    res.json({
      success: true,
      data: {
        restaurants,
        pagination: {
          current: page,
          pages: Math.ceil(totalResult.length / limit),
          total: totalResult.length
        }
      }
    });
  } catch (error) {
    console.error('Get restaurants error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error'
    });
  }
});

// @desc    Get restaurant by ID
// @route   GET /api/restaurants/:id
// @access  Public
router.get('/:id', async (req, res) => {
  try {
    const restaurants = await query(
      'restaurants',
      where: 'id = $1 AND is_active = $2',
      whereArgs: [req.params.id, true]
    );

    if (restaurants.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Restaurant not found'
      });
    }

    res.json({
      success: true,
      data: { restaurant: restaurants[0] }
    });
  } catch (error) {
    console.error('Get restaurant error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error'
    });
  }
});

// @desc    Create new restaurant
// @route   POST /api/restaurants
// @access  Private/Restaurant Owner
router.post('/', protect, authorize('Restaurant Owner'), async (req, res) => {
  try {
    const {
      name,
      location,
      parkId,
      cuisineType,
      priceRange,
      description,
      imagePath,
      contactPhone,
      openingHours
    } = req.body;

    const restaurantData = {
      id: `restaurant_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`,
      name,
      location,
      park_id: parkId,
      cuisine_type: cuisineType,
      price_range: priceRange,
      description,
      image_path: imagePath,
      contact_phone: contactPhone,
      opening_hours: openingHours,
      rating: 0.0,
      total_reviews: 0,
      is_active: true,
      created_at: Date.now(),
      updated_at: Date.now()
    };

    const result = await insert('restaurants', restaurantData);

    res.status(201).json({
      success: true,
      message: 'Restaurant created successfully',
      data: { restaurant: restaurantData }
    });
  } catch (error) {
    console.error('Create restaurant error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error'
    });
  }
});

// @desc    Update restaurant
// @route   PUT /api/restaurants/:id
// @access  Private/Restaurant Owner
router.put('/:id', protect, authorize('Restaurant Owner'), async (req, res) => {
  try {
    const updateData = {
      ...req.body,
      updated_at: Date.now()
    };

    const result = await update(
      'restaurants',
      updateData,
      where: 'id = $1',
      whereArgs: [req.params.id]
    );

    if (result === 0) {
      return res.status(404).json({
        success: false,
        message: 'Restaurant not found'
      });
    }

    res.json({
      success: true,
      message: 'Restaurant updated successfully'
    });
  } catch (error) {
    console.error('Update restaurant error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error'
    });
  }
});

// @desc    Delete restaurant
// @route   DELETE /api/restaurants/:id
// @access  Private/Restaurant Owner
router.delete('/:id', protect, authorize('Restaurant Owner'), async (req, res) => {
  try {
    const result = await update(
      'restaurants',
      { is_active: false, updated_at: Date.now() },
      where: 'id = $1',
      whereArgs: [req.params.id]
    );

    if (result === 0) {
      return res.status(404).json({
        success: false,
        message: 'Restaurant not found'
      });
    }

    res.json({
      success: true,
      message: 'Restaurant deleted successfully'
    });
  } catch (error) {
    console.error('Delete restaurant error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error'
    });
  }
});

module.exports = router;
