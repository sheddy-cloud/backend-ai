const express = require('express');
const Booking = require('../models/Booking');
const Tour = require('../models/Tour');
const { protect } = require('../middleware/auth');

const router = express.Router();

// @desc    Create new booking
// @route   POST /api/bookings
// @access  Private
router.post('/', protect, async (req, res) => {
  try {
    const { tourId, participants, startDate, specialRequests, emergencyContact } = req.body;

    // Get tour details
    const tour = await Tour.findById(tourId);
    if (!tour || !tour.isActive || !tour.isAvailable) {
      return res.status(404).json({
        success: false,
        message: 'Tour not available'
      });
    }

    // Check if tour is available on the requested date
    if (!tour.isAvailableOnDate(new Date(startDate))) {
      return res.status(400).json({
        success: false,
        message: 'Tour not available on the requested date'
      });
    }

    // Calculate total participants
    const totalParticipants = participants.adults + participants.children + participants.infants;

    // Check if there are enough spots
    if (totalParticipants > tour.spotsRemaining) {
      return res.status(400).json({
        success: false,
        message: 'Not enough spots available'
      });
    }

    // Calculate end date
    const endDate = new Date(startDate);
    endDate.setDate(endDate.getDate() + tour.durationDays);

    // Calculate total price
    const totalPrice = tour.priceUsd * totalParticipants;

    // Create booking
    const booking = new Booking({
      user: req.user._id,
      tour: tourId,
      participants,
      totalParticipants,
      startDate: new Date(startDate),
      endDate,
      totalPrice,
      specialRequests,
      emergencyContact
    });

    await booking.save();

    // Update tour participants
    await tour.bookSpots(totalParticipants, new Date(startDate));

    // Populate booking data
    await booking.populate([
      { path: 'tour', select: 'title durationDays' },
      { path: 'user', select: 'name email' }
    ]);

    res.status(201).json({
      success: true,
      message: 'Booking created successfully',
      data: { booking }
    });
  } catch (error) {
    console.error('Create booking error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error'
    });
  }
});

// @desc    Get user bookings
// @route   GET /api/bookings
// @access  Private
router.get('/', protect, async (req, res) => {
  try {
    const bookings = await Booking.findByUser(req.user._id);

    res.json({
      success: true,
      data: { bookings }
    });
  } catch (error) {
    console.error('Get bookings error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error'
    });
  }
});

// @desc    Get booking by ID
// @route   GET /api/bookings/:id
// @access  Private
router.get('/:id', protect, async (req, res) => {
  try {
    const booking = await Booking.findById(req.params.id)
      .populate('tour', 'title durationDays priceUsd')
      .populate('user', 'name email phone');

    if (!booking) {
      return res.status(404).json({
        success: false,
        message: 'Booking not found'
      });
    }

    // Check if user owns this booking
    if (booking.user._id.toString() !== req.user._id.toString()) {
      return res.status(403).json({
        success: false,
        message: 'Access denied'
      });
    }

    res.json({
      success: true,
      data: { booking }
    });
  } catch (error) {
    console.error('Get booking error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error'
    });
  }
});

// @desc    Cancel booking
// @route   PUT /api/bookings/:id/cancel
// @access  Private
router.put('/:id/cancel', protect, async (req, res) => {
  try {
    const { reason } = req.body;
    const booking = await Booking.findById(req.params.id);

    if (!booking) {
      return res.status(404).json({
        success: false,
        message: 'Booking not found'
      });
    }

    // Check if user owns this booking
    if (booking.user.toString() !== req.user._id.toString()) {
      return res.status(403).json({
        success: false,
        message: 'Access denied'
      });
    }

    // Check if booking can be cancelled
    if (booking.status === 'cancelled' || booking.status === 'completed') {
      return res.status(400).json({
        success: false,
        message: 'Booking cannot be cancelled'
      });
    }

    // Cancel booking
    await booking.cancel(reason);

    // Update tour participants
    const tour = await Tour.findById(booking.tour);
    if (tour) {
      await tour.cancelBooking(booking.totalParticipants, booking.startDate);
    }

    res.json({
      success: true,
      message: 'Booking cancelled successfully',
      data: { booking }
    });
  } catch (error) {
    console.error('Cancel booking error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error'
    });
  }
});

module.exports = router;
