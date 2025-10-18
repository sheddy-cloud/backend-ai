const express = require('express');
const { protect, authorize } = require('../middleware/auth');
const { getRows, getRow, execute } = require('../database/config');

const router = express.Router();

// @desc    Get all travel gear
// @route   GET /api/travel-gear
// @access  Public
router.get('/', async (req, res) => {
  try {
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 10;
    const offset = (page - 1) * limit;
    const { category, brand, minPrice, maxPrice } = req.query;

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
      whereClause += ` AND brand ILIKE $${paramCount}`;
      params.push(`%${brand}%`);
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

    const gear = await getRows(`
      SELECT * FROM travel_gear 
      WHERE ${whereClause}
      ORDER BY rating DESC, created_at DESC
      LIMIT $${paramCount + 1} OFFSET $${paramCount + 2}
    `, [...params, limit, offset]);

    const totalResult = await getRow(`
      SELECT COUNT(*) as count FROM travel_gear 
      WHERE ${whereClause}
    `, params);

    res.json({
      success: true,
      data: {
        gear,
        pagination: {
          current: page,
          pages: Math.ceil(totalResult.count / limit),
          total: parseInt(totalResult.count)
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
    const gear = await getRow(
      'SELECT * FROM travel_gear WHERE id = $1 AND is_active = $2',
      [req.params.id, true]
    );

    if (!gear) {
      return res.status(404).json({
        success: false,
        message: 'Travel gear not found'
      });
    }

    res.json({
      success: true,
      data: { gear }
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
    const gearData = {
      ...req.body,
      seller_id: req.user.id,
      is_active: true,
      created_at: Date.now(),
      updated_at: Date.now()
    };

    const result = await execute(
      `INSERT INTO travel_gear (id, name, description, category, brand, price_usd, rating, total_reviews, seller_id, is_active, created_at, updated_at)
       VALUES (gen_random_uuid(), $1, $2, $3, $4, $5, $6, $7, $8, $9, NOW(), NOW())
       RETURNING *`,
      [gearData.name, gearData.description, gearData.category, gearData.brand,
       gearData.price_usd, gearData.rating || 0, gearData.total_reviews || 0, gearData.seller_id, gearData.is_active]
    );

    res.status(201).json({
      success: true,
      message: 'Travel gear created successfully',
      data: { gear: result.rows[0] }
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
    const updateData = {
      ...req.body,
      updated_at: Date.now()
    };

    const setClause = Object.keys(updateData).map((key, index) => `${key} = $${index + 1}`).join(', ');
    const values = Object.values(updateData);
    const result = await execute(
      `UPDATE travel_gear SET ${setClause}, updated_at = NOW() WHERE id = $${values.length + 1} RETURNING *`,
      [...values, req.params.id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Travel gear not found'
      });
    }

    res.json({
      success: true,
      message: 'Travel gear updated successfully',
      data: { gear: result.rows[0] }
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
    const result = await execute(
      'UPDATE travel_gear SET is_active = $1, updated_at = NOW() WHERE id = $2 RETURNING *',
      [false, req.params.id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Travel gear not found'
      });
    }

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

module.exports = router;