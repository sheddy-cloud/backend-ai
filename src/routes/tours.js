const express = require('express');
const Tour = require('../models/Tour');
const { protect, authorize, optionalAuth } = require('../middleware/auth');

const router = express.Router();

// @desc    Get all tours
// @route   GET /api/tours
// @access  Public
router.get('/', optionalAuth, async (req, res) => {
  try {
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 10;
    const skip = (page - 1) * limit;
    const { park, agency, search, minPrice, maxPrice, duration } = req.query;

    let query = { isActive: true, isAvailable: true };

    if (park) query.park = park;
    if (agency) query.agency = agency;
    if (minPrice || maxPrice) {
      query.priceUsd = {};
      if (minPrice) query.priceUsd.$gte = parseFloat(minPrice);
      if (maxPrice) query.priceUsd.$lte = parseFloat(maxPrice);
    }
    if (duration) query.durationDays = parseInt(duration);

    if (search) {
      query.$or = [
        { title: new RegExp(search, 'i') },
        { description: new RegExp(search, 'i') },
        { tags: new RegExp(search, 'i') }
      ];
    }

    const tours = await Tour.find(query)
      .populate('park', 'name location')
      .populate('agency', 'name companyName')
      .sort({ 'rating.average': -1 })
      .skip(skip)
      .limit(limit);

    const total = await Tour.countDocuments(query);

    res.json({
      success: true,
      data: {
        tours,
        pagination: {
          current: page,
          pages: Math.ceil(total / limit),
          total
        }
      }
    });
  } catch (error) {
    console.error('Get tours error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error'
    });
  }
});

// @desc    Get tour by ID
// @route   GET /api/tours/:id
// @access  Public
router.get('/:id', optionalAuth, async (req, res) => {
  try {
    const tour = await Tour.findById(req.params.id)
      .populate('park', 'name location description wildlife')
      .populate('agency', 'name companyName location');

    if (!tour || !tour.isActive) {
      return res.status(404).json({
        success: false,
        message: 'Tour not found'
      });
    }

    res.json({
      success: true,
      data: { tour }
    });
  } catch (error) {
    console.error('Get tour error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error'
    });
  }
});

// @desc    Create new tour
// @route   POST /api/tours
// @access  Private/Travel Agency
router.post('/', protect, authorize('Travel Agency'), async (req, res) => {
  try {
    const tourData = {
      ...req.body,
      agency: req.user._id
    };

    const tour = await Tour.create(tourData);

    res.status(201).json({
      success: true,
      message: 'Tour created successfully',
      data: { tour }
    });
  } catch (error) {
    console.error('Create tour error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error'
    });
  }
});

// @desc    Update tour
// @route   PUT /api/tours/:id
// @access  Private/Travel Agency
router.put('/:id', protect, authorize('Travel Agency'), async (req, res) => {
  try {
    const tour = await Tour.findById(req.params.id);

    if (!tour) {
      return res.status(404).json({
        success: false,
        message: 'Tour not found'
      });
    }

    // Check if user owns this tour
    if (tour.agency.toString() !== req.user._id.toString()) {
      return res.status(403).json({
        success: false,
        message: 'Access denied'
      });
    }

    const updatedTour = await Tour.findByIdAndUpdate(
      req.params.id,
      req.body,
      { new: true, runValidators: true }
    );

    res.json({
      success: true,
      message: 'Tour updated successfully',
      data: { tour: updatedTour }
    });
  } catch (error) {
    console.error('Update tour error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error'
    });
  }
});

// @desc    Get tours by park
// @route   GET /api/tours/park/:parkId
// @access  Public
router.get('/park/:parkId', optionalAuth, async (req, res) => {
  try {
    const tours = await Tour.findByPark(req.params.parkId);

    res.json({
      success: true,
      data: { tours }
    });
  } catch (error) {
    console.error('Get tours by park error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error'
    });
  }
});

// @desc    Get tours by agency
// @route   GET /api/tours/agency/:agencyId
// @access  Public
router.get('/agency/:agencyId', optionalAuth, async (req, res) => {
  try {
    const tours = await Tour.findByAgency(req.params.agencyId);

    res.json({
      success: true,
      data: { tours }
    });
  } catch (error) {
    console.error('Get tours by agency error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error'
    });
  }
});

module.exports = router;
