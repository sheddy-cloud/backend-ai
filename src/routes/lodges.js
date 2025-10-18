const express = require('express');
const { protect, authorize } = require('../middleware/auth');
const { getRows, getRow, execute } = require('../database/config');

const router = express.Router();

// @desc    Get all lodges
// @route   GET /api/lodges
// @access  Public
router.get('/', async (req, res) => {
  try {
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 10;
    const offset = (page - 1) * limit;
    const { park, location, type, minPrice, maxPrice } = req.query;

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

    if (type) {
      paramCount++;
      whereClause += ` AND lodge_type = $${paramCount}`;
      params.push(type);
    }

    if (minPrice) {
      paramCount++;
      whereClause += ` AND price_per_night_usd >= $${paramCount}`;
      params.push(parseFloat(minPrice));
    }

    if (maxPrice) {
      paramCount++;
      whereClause += ` AND price_per_night_usd <= $${paramCount}`;
      params.push(parseFloat(maxPrice));
    }

    const lodges = await getRows(`
      SELECT * FROM lodges 
      WHERE ${whereClause}
      ORDER BY rating DESC, created_at DESC
      LIMIT $${paramCount + 1} OFFSET $${paramCount + 2}
    `, [...params, limit, offset]);

    const totalResult = await getRow(`
      SELECT COUNT(*) as count FROM lodges 
      WHERE ${whereClause}
    `, params);

    res.json({
      success: true,
      data: {
        lodges,
        pagination: {
          current: page,
          pages: Math.ceil(totalResult.count / limit),
          total: parseInt(totalResult.count)
        }
      }
    });
  } catch (error) {
    console.error('Get lodges error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error'
    });
  }
});

// @desc    Get lodge by ID
// @route   GET /api/lodges/:id
// @access  Public
router.get('/:id', async (req, res) => {
  try {
    const lodge = await getRow(
      'SELECT * FROM lodges WHERE id = $1 AND is_active = $2',
      [req.params.id, true]
    );

    if (!lodge) {
      return res.status(404).json({
        success: false,
        message: 'Lodge not found'
      });
    }

    // Get rooms for this lodge
    const rooms = await getRows(
      'SELECT * FROM rooms WHERE lodge_id = $1 AND is_available = $2',
      [req.params.id, true]
    );

    res.json({
      success: true,
      data: {
        lodge: lodge,
        rooms
      }
    });
  } catch (error) {
    console.error('Get lodge error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error'
    });
  }
});

// @desc    Create new lodge
// @route   POST /api/lodges
// @access  Private/Lodge Owner
router.post('/', protect, authorize('Lodge Owner'), async (req, res) => {
  try {
    const {
      name,
      location,
      parkId,
      lodgeType,
      capacity,
      pricePerNightUsd,
      amenities,
      description,
      imagePath,
      contactEmail,
      contactPhone
    } = req.body;

    const lodgeData = {
      id: `lodge_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`,
      name,
      location,
      park_id: parkId,
      lodge_type: lodgeType,
      capacity: parseInt(capacity),
      price_per_night_usd: parseFloat(pricePerNightUsd),
      amenities: Array.isArray(amenities) ? amenities : [],
      description,
      image_path: imagePath,
      contact_email: contactEmail,
      contact_phone: contactPhone,
      rating: 0.0,
      total_reviews: 0,
      is_active: true,
      created_at: Date.now(),
      updated_at: Date.now()
    };

    const result = await execute(
      `INSERT INTO lodges (id, name, description, location, lodge_type, price_per_night_usd, rating, total_reviews, is_active, created_at, updated_at)
       VALUES (gen_random_uuid(), $1, $2, $3, $4, $5, $6, $7, $8, NOW(), NOW())
       RETURNING *`,
      [lodgeData.name, lodgeData.description, lodgeData.location, lodgeData.lodge_type, 
       lodgeData.price_per_night_usd, lodgeData.rating, lodgeData.total_reviews, lodgeData.is_active]
    );

    res.status(201).json({
      success: true,
      message: 'Lodge created successfully',
      data: { lodge: lodgeData }
    });
  } catch (error) {
    console.error('Create lodge error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error'
    });
  }
});

// @desc    Update lodge
// @route   PUT /api/lodges/:id
// @access  Private/Lodge Owner
router.put('/:id', protect, authorize('Lodge Owner'), async (req, res) => {
  try {
    const updateData = {
      ...req.body,
      updated_at: Date.now()
    };

    const setClause = Object.keys(updateData).map((key, index) => `${key} = $${index + 1}`).join(', ');
    const values = Object.values(updateData);
    const result = await execute(
      `UPDATE lodges SET ${setClause}, updated_at = NOW() WHERE id = $${values.length + 1} RETURNING *`,
      [...values, req.params.id]
    );

    if (result === 0) {
      return res.status(404).json({
        success: false,
        message: 'Lodge not found'
      });
    }

    res.json({
      success: true,
      message: 'Lodge updated successfully'
    });
  } catch (error) {
    console.error('Update lodge error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error'
    });
  }
});

// @desc    Delete lodge
// @route   DELETE /api/lodges/:id
// @access  Private/Lodge Owner
router.delete('/:id', protect, authorize('Lodge Owner'), async (req, res) => {
  try {
    const result = await execute(
      'UPDATE lodges SET is_active = $1, updated_at = NOW() WHERE id = $2 RETURNING *',
      [false, req.params.id]
    );

    if (result === 0) {
      return res.status(404).json({
        success: false,
        message: 'Lodge not found'
      });
    }

    res.json({
      success: true,
      message: 'Lodge deleted successfully'
    });
  } catch (error) {
    console.error('Delete lodge error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error'
    });
  }
});

// @desc    Add room to lodge
// @route   POST /api/lodges/:id/rooms
// @access  Private/Lodge Owner
router.post('/:id/rooms', protect, authorize('Lodge Owner'), async (req, res) => {
  try {
    const {
      roomType,
      roomNumber,
      capacity,
      pricePerNightUsd,
      amenities
    } = req.body;

    const roomData = {
      id: `room_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`,
      lodge_id: req.params.id,
      room_type: roomType,
      room_number: roomNumber,
      capacity: parseInt(capacity),
      price_per_night_usd: parseFloat(pricePerNightUsd),
      amenities: Array.isArray(amenities) ? amenities : [],
      is_available: true,
      created_at: Date.now(),
      updated_at: Date.now()
    };

    const result = await execute(
      `INSERT INTO rooms (id, lodge_id, room_type, price_per_night_usd, capacity, amenities, is_available, created_at, updated_at)
       VALUES (gen_random_uuid(), $1, $2, $3, $4, $5, $6, NOW(), NOW())
       RETURNING *`,
      [roomData.lodge_id, roomData.room_type, roomData.price_per_night_usd, 
       roomData.capacity, JSON.stringify(roomData.amenities), roomData.is_available]
    );

    res.status(201).json({
      success: true,
      message: 'Room added successfully',
      data: { room: roomData }
    });
  } catch (error) {
    console.error('Add room error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error'
    });
  }
});

module.exports = router;