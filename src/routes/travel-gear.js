const express = require('express');
const { protect, authorize } = require('../middleware/auth');
const { query, insert, update, delete: deleteRecord } = require('../config/database');

const router = express.Router();

// @desc    Get all travel gear
// @route   GET /api/travel-gear
// @access  Public
router.get('/', async (req, res) => {
  try {
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 10;
    const offset = (page - 1) * limit;
    const { category, brand, minPrice, maxPrice, search } = req.query;

    let whereClause = 'is_active = $1';
    let params = [true];
    let paramCount = 1;

    if (category) {
      paramCount++;
      whereClause += ` AND category = $${paramCount}`;
      params.push(category);
    }

    if (brand) {
      paramCount++;
      whereClause += ` AND brand = $${paramCount}`;
      params.push(brand);
    }

    if (minPrice) {
      paramCount++;
      whereClause += ` AND price_usd >= $${paramCount}`;
      params.push(parseFloat(minPrice));
    }

    if (maxPrice) {
      paramCount++;
      whereClause += ` AND price_usd <= $${paramCount}`;
      params.push(parseFloat(maxPrice));
    }

    if (search) {
      paramCount++;
      whereClause += ` AND (name ILIKE $${paramCount} OR description ILIKE $${paramCount})`;
      params.push(`%${search}%`);
    }

    const gear = await query(
      'travel_gear',
      where: whereClause,
      whereArgs: params,
      orderBy: 'rating DESC, created_at DESC',
      limit: limit,
      offset: offset
    );

    const totalResult = await query(
      'travel_gear',
      where: whereClause,
      whereArgs: params
    );

    res.json({
      success: true,
      data: {
        gear,
        pagination: {
          current: page,
          pages: Math.ceil(totalResult.length / limit),
          total: totalResult.length
        }
      }
    });
  } catch (error) {
    console.error('Get travel gear error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error'
    });
  }
});

// @desc    Get travel gear by ID
// @route   GET /api/travel-gear/:id
// @access  Public
router.get('/:id', async (req, res) => {
  try {
    const gear = await query(
      'travel_gear',
      where: 'id = $1 AND is_active = $2',
      whereArgs: [req.params.id, true]
    );

    if (gear.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Travel gear not found'
      });
    }

    res.json({
      success: true,
      data: { gear: gear[0] }
    });
  } catch (error) {
    console.error('Get travel gear error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error'
    });
  }
});

// @desc    Create new travel gear
// @route   POST /api/travel-gear
// @access  Private/Travel Gear Seller
router.post('/', protect, authorize('Travel Gear Seller'), async (req, res) => {
  try {
    const {
      name,
      category,
      description,
      priceUsd,
      brand,
      imagePath,
      specifications,
      availability
    } = req.body;

    const gearData = {
      id: `gear_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`,
      name,
      category,
      description,
      price_usd: parseFloat(priceUsd),
      brand,
      image_path: imagePath,
      specifications: specifications || {},
      availability: parseInt(availability) || 1,
      seller_id: req.user.id,
      rating: 0.0,
      total_reviews: 0,
      is_active: true,
      created_at: Date.now(),
      updated_at: Date.now()
    };

    const result = await insert('travel_gear', gearData);

    res.status(201).json({
      success: true,
      message: 'Travel gear created successfully',
      data: { gear: gearData }
    });
  } catch (error) {
    console.error('Create travel gear error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error'
    });
  }
});

// @desc    Update travel gear
// @route   PUT /api/travel-gear/:id
// @access  Private/Travel Gear Seller
router.put('/:id', protect, authorize('Travel Gear Seller'), async (req, res) => {
  try {
    // Check if user owns this gear
    const gear = await query(
      'travel_gear',
      where: 'id = $1 AND seller_id = $2',
      whereArgs: [req.params.id, req.user.id]
    );

    if (gear.length === 0) {
      return res.status(403).json({
        success: false,
        message: 'Access denied'
      });
    }

    const updateData = {
      ...req.body,
      updated_at: Date.now()
    };

    const result = await update(
      'travel_gear',
      updateData,
      where: 'id = $1',
      whereArgs: [req.params.id]
    );

    res.json({
      success: true,
      message: 'Travel gear updated successfully'
    });
  } catch (error) {
    console.error('Update travel gear error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error'
    });
  }
});

// @desc    Delete travel gear
// @route   DELETE /api/travel-gear/:id
// @access  Private/Travel Gear Seller
router.delete('/:id', protect, authorize('Travel Gear Seller'), async (req, res) => {
  try {
    // Check if user owns this gear
    const gear = await query(
      'travel_gear',
      where: 'id = $1 AND seller_id = $2',
      whereArgs: [req.params.id, req.user.id]
    );

    if (gear.length === 0) {
      return res.status(403).json({
        success: false,
        message: 'Access denied'
      });
    }

    const result = await update(
      'travel_gear',
      { is_active: false, updated_at: Date.now() },
      where: 'id = $1',
      whereArgs: [req.params.id]
    );

    res.json({
      success: true,
      message: 'Travel gear deleted successfully'
    });
  } catch (error) {
    console.error('Delete travel gear error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error'
    });
  }
});

// @desc    Get travel gear by seller
// @route   GET /api/travel-gear/seller/:sellerId
// @access  Public
router.get('/seller/:sellerId', async (req, res) => {
  try {
    const gear = await query(
      'travel_gear',
      where: 'seller_id = $1 AND is_active = $2',
      whereArgs: [req.params.sellerId, true],
      orderBy: 'created_at DESC'
    );

    res.json({
      success: true,
      data: { gear }
    });
  } catch (error) {
    console.error('Get travel gear by seller error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error'
    });
  }
});

module.exports = router;
