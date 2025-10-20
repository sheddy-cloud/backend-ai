const express = require('express');
const Park = require('../models/Park');
const { protect, authorize, optionalAuth } = require('../middleware/auth');

const router = express.Router();

// @desc    Get all parks
// @route   GET /api/parks
// @access  Public
router.get('/', optionalAuth, async (req, res) => {
  try {
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 10;
    const skip = (page - 1) * limit;
    const { location, search } = req.query;

    let query = { isActive: true };

    // Filter by location
    if (location) {
      query.location = new RegExp(location, 'i');
    }

    // Search functionality
    if (search) {
      query.$or = [
        { name: new RegExp(search, 'i') },
        { description: new RegExp(search, 'i') },
        { wildlife: new RegExp(search, 'i') }
      ];
    }

    const parks = await Park.find({ ...query, limit: limit, offset: skip });
    const total = await Park.count(query);

    res.json({
      success: true,
      data: {
        parks,
        pagination: {
          current: page,
          pages: Math.ceil(total / limit),
          total
        }
      }
    });
  } catch (error) {
    console.error('Get parks error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error'
    });
  }
});

// @desc    Get park by ID
// @route   GET /api/parks/:id
// @access  Public
router.get('/:id', optionalAuth, async (req, res) => {
  try {
    const park = await Park.findById(req.params.id);

    if (!park || !park.isActive) {
      return res.status(404).json({
        success: false,
        message: 'Park not found'
      });
    }

    res.json({
      success: true,
      data: { park }
    });
  } catch (error) {
    console.error('Get park error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error'
    });
  }
});

// @desc    Create new park
// @route   POST /api/parks
// @access  Private/Admin
router.post('/', protect, authorize('Admin'), async (req, res) => {
  try {
    const park = await Park.create(req.body);

    res.status(201).json({
      success: true,
      message: 'Park created successfully',
      data: { park }
    });
  } catch (error) {
    console.error('Create park error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error'
    });
  }
});

// @desc    Update park
// @route   PUT /api/parks/:id
// @access  Private/Admin
router.put('/:id', protect, authorize('Admin'), async (req, res) => {
  try {
    const park = await Park.findByIdAndUpdate(
      req.params.id,
      req.body
    );

    if (!park) {
      return res.status(404).json({
        success: false,
        message: 'Park not found'
      });
    }

    res.json({
      success: true,
      message: 'Park updated successfully',
      data: { park }
    });
  } catch (error) {
    console.error('Update park error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error'
    });
  }
});

// @desc    Delete park
// @route   DELETE /api/parks/:id
// @access  Private/Admin
router.delete('/:id', protect, authorize('Admin'), async (req, res) => {
  try {
    const park = await Park.findByIdAndUpdate(
      req.params.id,
      { isActive: false }
    );

    if (!park) {
      return res.status(404).json({
        success: false,
        message: 'Park not found'
      });
    }

    res.json({
      success: true,
      message: 'Park deleted successfully'
    });
  } catch (error) {
    console.error('Delete park error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error'
    });
  }
});

// @desc    Get parks by location
// @route   GET /api/parks/location/:location
// @access  Public
router.get('/location/:location', optionalAuth, async (req, res) => {
  try {
    const { location } = req.params;
    const parks = await Park.findByLocation(location);

    res.json({
      success: true,
      data: { parks }
    });
  } catch (error) {
    console.error('Get parks by location error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error'
    });
  }
});

// @desc    Get nearby parks
// @route   GET /api/parks/nearby
// @access  Public
router.get('/nearby', optionalAuth, async (req, res) => {
  try {
    const { latitude, longitude, maxDistance } = req.query;

    if (!latitude || !longitude) {
      return res.status(400).json({
        success: false,
        message: 'Latitude and longitude are required'
      });
    }

    const parks = await Park.findNearby(
      parseFloat(latitude),
      parseFloat(longitude),
      maxDistance ? parseFloat(maxDistance) : 100
    );

    res.json({
      success: true,
      data: { parks }
    });
  } catch (error) {
    console.error('Get nearby parks error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error'
    });
  }
});

module.exports = router;
