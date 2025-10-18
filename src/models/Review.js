const { getRows, getRow, execute } = require('../database/config');

// Review model using raw PostgreSQL queries
class Review {
  constructor(data) {
    this.id = data.id;
    this.userId = data.userId;
    this.entityId = data.entityId;
    this.entityType = data.entityType;
    this.rating = data.rating;
    this.comment = data.comment;
    this.isActive = data.isActive;
    this.createdAt = data.createdAt;
    this.updatedAt = data.updatedAt;
  }

  static async find(options = {}) {
    try {
      let query = 'SELECT * FROM reviews WHERE deleted_at IS NULL';
      const params = [];
      let paramCount = 0;

      if (options.entityId) {
        paramCount++;
        query += ` AND entity_id = $${paramCount}`;
        params.push(options.entityId);
      }

      if (options.entityType) {
        paramCount++;
        query += ` AND entity_type = $${paramCount}`;
        params.push(options.entityType);
      }

      if (options.isActive !== undefined) {
        paramCount++;
        query += ` AND is_active = $${paramCount}`;
        params.push(options.isActive);
      }

      query += ' ORDER BY created_at DESC';

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

      const reviews = await getRows(query, params);
      return reviews.map(review => new Review(review));
    } catch (error) {
      console.error('Error finding reviews:', error);
      throw error;
    }
  }

  static async findById(id) {
    try {
      const review = await getRow(
        'SELECT * FROM reviews WHERE id = $1 AND deleted_at IS NULL',
        [id]
      );
      return review ? new Review(review) : null;
    } catch (error) {
      console.error('Error finding review by ID:', error);
      throw error;
    }
  }

  static async create(reviewData) {
    try {
      const result = await execute(
        `INSERT INTO reviews (id, user_id, entity_id, entity_type, rating, comment, is_active, created_at, updated_at)
         VALUES (gen_random_uuid(), $1, $2, $3, $4, $5, true, NOW(), NOW())
         RETURNING *`,
        [reviewData.userId, reviewData.entityId, reviewData.entityType, reviewData.rating, reviewData.comment]
      );
      return new Review(result.rows[0]);
    } catch (error) {
      console.error('Error creating review:', error);
      throw error;
    }
  }
}

module.exports = Review;
