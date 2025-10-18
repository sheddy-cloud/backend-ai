const express = require('express');
const Review = require('../models/Review');
const { protect } = require('../middleware/auth');

const router = express.Router();

// @desc    Create new review
// @route   POST /api/reviews
// @access  Private
router.post('/', protect, async (req, res) => {
  try {
    const { tourId, bookingId, rating, title, comment, pros, cons } = req.body;

    // Check if user has a completed booking for this tour
    const existingReview = await Review.findOne({
      user: req.user._id,
      tour: tourId,
      booking: bookingId
    });

    if (existingReview) {
      return res.status(400).json({
        success: false,
        message: 'You have already reviewed this tour'
      });
    }

    const review = new Review({
      user: req.user._id,
      tour: tourId,
      booking: bookingId,
      rating,
      title,
      comment,
      pros,
      cons
    });

    await review.save();

    // Update tour rating
    const Tour = require('../models/Tour');
    const tour = await Tour.findById(tourId);
    if (tour) {
      await tour.updateRating(rating.overall);
    }

    res.status(201).json({
      success: true,
      message: 'Review created successfully',
      data: { review }
    });
  } catch (error) {
    console.error('Create review error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error'
    });
  }
});

// @desc    Get reviews for a tour
// @route   GET /api/reviews/tour/:tourId
// @access  Public
router.get('/tour/:tourId', async (req, res) => {
  try {
    const reviews = await Review.findByTour(req.params.tourId);

    res.json({
      success: true,
      data: { reviews }
    });
  } catch (error) {
    console.error('Get tour reviews error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error'
    });
  }
});

// @desc    Get user reviews
// @route   GET /api/reviews
// @access  Private
router.get('/', protect, async (req, res) => {
  try {
    const reviews = await Review.findByUser(req.user._id);

    res.json({
      success: true,
      data: { reviews }
    });
  } catch (error) {
    console.error('Get user reviews error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error'
    });
  }
});

// @desc    Mark review as helpful
// @route   PUT /api/reviews/:id/helpful
// @access  Private
router.put('/:id/helpful', protect, async (req, res) => {
  try {
    const review = await Review.findById(req.params.id);

    if (!review) {
      return res.status(404).json({
        success: false,
        message: 'Review not found'
      });
    }

    await review.markHelpful(req.user._id);

    res.json({
      success: true,
      message: 'Review marked as helpful',
      data: { review }
    });
  } catch (error) {
    console.error('Mark review helpful error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error'
    });
  }
});

module.exports = router;
