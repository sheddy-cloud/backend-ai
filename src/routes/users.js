const express = require('express');
const User = require('../models/User');
const { protect, authorize } = require('../middleware/auth');

const router = express.Router();

// @desc    Get all users (Admin only)
// @route   GET /api/users
// @access  Private/Admin
router.get('/', protect, authorize('Admin'), async (req, res) => {
  try {
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 10;
    const skip = (page - 1) * limit;

    const users = await User.find({ isActive: true, limit: limit, offset: skip });
    const total = await User.count({ isActive: true });

    res.json({
      success: true,
      data: {
        users,
        pagination: {
          current: page,
          pages: Math.ceil(total / limit),
          total
        }
      }
    });
  } catch (error) {
    console.error('Get users error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error'
    });
  }
});

// @desc    Get users by role
// @route   GET /api/users/role/:role
// @access  Private
router.get('/role/:role', protect, async (req, res) => {
  try {
    const { role } = req.params;
    const users = await User.findByRole(role);

    res.json({
      success: true,
      data: { users }
    });
  } catch (error) {
    console.error('Get users by role error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error'
    });
  }
});

// @desc    Get user by ID
// @route   GET /api/users/:id
// @access  Private
router.get('/:id', protect, async (req, res) => {
  try {
    const user = await User.findById(req.params.id);
    
    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User not found'
      });
    }

    res.json({
      success: true,
      data: { user }
    });
  } catch (error) {
    console.error('Get user error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error'
    });
  }
});

// @desc    Deactivate user
// @route   PUT /api/users/:id/deactivate
// @access  Private/Admin
router.put('/:id/deactivate', protect, authorize('Admin'), async (req, res) => {
  try {
    const user = await User.findByIdAndUpdate(
      req.params.id,
      { isActive: false }
    );

    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User not found'
      });
    }

    res.json({
      success: true,
      message: 'User deactivated successfully',
      data: { user }
    });
  } catch (error) {
    console.error('Deactivate user error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error'
    });
  }
});

// @desc    Get user statistics
// @route   GET /api/users/stats/overview
// @access  Private/Admin
router.get('/stats/overview', protect, authorize('Admin'), async (req, res) => {
  try {
    // Get basic stats using our PostgreSQL model
    const totalUsers = await User.count();
    const activeUsers = await User.count({ isActive: true });
    
    // Get role-based stats
    const roleStats = [];
    const roles = ['Tourist', 'Travel Agency', 'Lodge Owner', 'Restaurant Owner', 'Travel Gear Seller', 'Photographer', 'Tour Guide'];
    
    for (const role of roles) {
      const count = await User.count({ role: role });
      const activeCount = await User.count({ role: role, isActive: true });
      roleStats.push({
        _id: role,
        count: count,
        activeCount: activeCount
      });
    }

    res.json({
      success: true,
      data: {
        totalUsers,
        activeUsers,
        roleStats: stats
      }
    });
  } catch (error) {
    console.error('Get user stats error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error'
    });
  }
});

module.exports = router;
