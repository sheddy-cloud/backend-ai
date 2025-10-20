const express = require('express');
const User = require('../models/User');
const { protect, authorize, optionalAuth } = require('../middleware/auth');

const router = express.Router();

// @desc    Get all travel agencies
// @route   GET /api/agencies
// @access  Public
router.get('/', optionalAuth, async (req, res) => {
  try {
    const agencies = await User.findByRole('Travel Agency');

    res.json({
      success: true,
      data: { agencies }
    });
  } catch (error) {
    console.error('Get agencies error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error'
    });
  }
});

// @desc    Get agency by ID
// @route   GET /api/agencies/:id
// @access  Public
router.get('/:id', optionalAuth, async (req, res) => {
  try {
    const agency = await User.findById(req.params.id);

    if (!agency || agency.role !== 'Travel Agency' || !agency.isActive) {
      return res.status(404).json({
        success: false,
        message: 'Travel agency not found'
      });
    }

    res.json({
      success: true,
      data: { agency }
    });
  } catch (error) {
    console.error('Get agency error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error'
    });
  }
});

module.exports = router;
