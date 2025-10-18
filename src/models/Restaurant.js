const { getRows, getRow, execute } = require('../database/config');

// Restaurant model using raw PostgreSQL queries
class Restaurant {
  constructor(data) {
    this.id = data.id;
    this.name = data.name;
    this.description = data.description;
    this.location = data.location;
    this.rating = data.rating;
    this.cuisine = data.cuisine;
    this.isActive = data.isActive;
    this.createdAt = data.createdAt;
    this.updatedAt = data.updatedAt;
  }

  static async find(options = {}) {
    try {
      let query = 'SELECT * FROM restaurants WHERE deleted_at IS NULL';
      const params = [];
      let paramCount = 0;

      if (options.isActive !== undefined) {
        paramCount++;
        query += ` AND is_active = $${paramCount}`;
        params.push(options.isActive);
      }

      query += ' ORDER BY rating DESC';

      if (options.limit) {
        paramCount++;
        query += ` LIMIT $${paramCount}`;
        params.push(options.limit);
      }

      if (options.skip) {
        paramCount++;
        query += ` OFFSET $${paramCount}`;
        params.push(options.skip);
      }

      const restaurants = await getRows(query, params);
      return restaurants.map(restaurant => new Restaurant(restaurant));
    } catch (error) {
      console.error('Error finding restaurants:', error);
      throw error;
    }
  }

  static async findById(id) {
    try {
      const restaurant = await getRow(
        'SELECT * FROM restaurants WHERE id = $1 AND deleted_at IS NULL',
        [id]
      );
      return restaurant ? new Restaurant(restaurant) : null;
    } catch (error) {
      console.error('Error finding restaurant by ID:', error);
      throw error;
    }
  }
}

module.exports = Restaurant;
