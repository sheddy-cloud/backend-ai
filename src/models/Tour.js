const { getRows, getRow, execute } = require('../database/config');

// Tour model using raw PostgreSQL queries
class Tour {
  constructor(data) {
    this.id = data.id;
    this.title = data.title;
    this.description = data.description;
    this.parkId = data.parkId;
    this.agencyId = data.agencyId;
    this.priceUsd = data.priceUsd;
    this.durationDays = data.durationDays;
    this.maxGroupSize = data.maxGroupSize;
    this.difficulty = data.difficulty;
    this.tags = data.tags;
    this.rating = data.rating;
    this.isActive = data.isActive;
    this.isAvailable = data.isAvailable;
    this.createdAt = data.createdAt;
    this.updatedAt = data.updatedAt;
  }

  static async find(options = {}) {
    try {
      let query = 'SELECT * FROM tours';
      const params = [];
      let paramCount = 0;

      if (options.isActive !== undefined) {
        paramCount++;
        query += ` AND is_active = $${paramCount}`;
        params.push(options.isActive);
      }

      if (options.isAvailable !== undefined) {
        paramCount++;
        query += ` AND is_available = $${paramCount}`;
        params.push(options.isAvailable);
      }

      if (options.parkId) {
        paramCount++;
        query += ` AND park_id = $${paramCount}`;
        params.push(options.parkId);
      }

      if (options.agencyId) {
        paramCount++;
        query += ` AND agency_id = $${paramCount}`;
        params.push(options.agencyId);
      }

      if (options.minPrice) {
        paramCount++;
        query += ` AND price_usd >= $${paramCount}`;
        params.push(options.minPrice);
      }

      if (options.maxPrice) {
        paramCount++;
        query += ` AND price_usd <= $${paramCount}`;
        params.push(options.maxPrice);
      }

      if (options.duration) {
        paramCount++;
        query += ` AND duration_days = $${paramCount}`;
        params.push(options.duration);
      }

      if (options.search) {
        paramCount++;
        query += ` AND (title ILIKE $${paramCount} OR description ILIKE $${paramCount} OR tags ILIKE $${paramCount})`;
        params.push(`%${options.search}%`);
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

      const tours = await getRows(query, params);
      return tours.map(tour => new Tour(tour));
    } catch (error) {
      console.error('Error finding tours:', error);
      throw error;
    }
  }

  static async findById(id) {
    try {
      const tour = await getRow(
        'SELECT * FROM tours WHERE id = $1',
        [id]
      );
      return tour ? new Tour(tour) : null;
    } catch (error) {
      console.error('Error finding tour by ID:', error);
      throw error;
    }
  }

  static async count(options = {}) {
    try {
      let query = 'SELECT COUNT(*) as count FROM tours';
      const params = [];
      let paramCount = 0;

      if (options.isActive !== undefined) {
        paramCount++;
        query += ` AND is_active = $${paramCount}`;
        params.push(options.isActive);
      }

      if (options.isAvailable !== undefined) {
        paramCount++;
        query += ` AND is_available = $${paramCount}`;
        params.push(options.isAvailable);
      }

      const result = await getRow(query, params);
      return parseInt(result.count);
    } catch (error) {
      console.error('Error counting tours:', error);
      throw error;
    }
  }

  static async create(tourData) {
    try {
      const result = await execute(
        `INSERT INTO tours (id, title, description, park_id, agency_id, price_usd, duration_days, max_group_size, difficulty, tags, rating, is_active, is_available, created_at, updated_at)
         VALUES (gen_random_uuid(), $1, $2, $3, $4, $5, $6, $7, $8, $9, $10, true, true, NOW(), NOW())
         RETURNING *`,
        [
          tourData.title, tourData.description, tourData.parkId, tourData.agencyId,
          tourData.priceUsd, tourData.durationDays, tourData.maxGroupSize,
          tourData.difficulty, JSON.stringify(tourData.tags || []), tourData.rating || 0
        ]
      );
      return new Tour(result.rows[0]);
    } catch (error) {
      console.error('Error creating tour:', error);
      throw error;
    }
  }

  static async findByIdAndUpdate(id, updateData, options = {}) {
    try {
      const setClause = [];
      const params = [];
      let paramCount = 0;

      Object.keys(updateData).forEach(key => {
        if (key === 'tags') {
          paramCount++;
          setClause.push(`tags = $${paramCount}`);
          params.push(JSON.stringify(updateData[key]));
        } else {
          paramCount++;
          setClause.push(`${key} = $${paramCount}`);
          params.push(updateData[key]);
        }
      });

      paramCount++;
      setClause.push(`updated_at = NOW()`);
      paramCount++;
      params.push(id);

      const query = `UPDATE tours SET ${setClause.join(', ')} 
                     WHERE id = $${paramCount} 
                     RETURNING *`;

      const result = await execute(query, params);
      return result.rows[0] ? new Tour(result.rows[0]) : null;
    } catch (error) {
      console.error('Error updating tour:', error);
      throw error;
    }
  }

  static async findByPark(parkId) {
    try {
      const tours = await getRows(
        'SELECT * FROM tours WHERE park_id = $1 ORDER BY rating DESC',
        [parkId]
      );
      return tours.map(tour => new Tour(tour));
    } catch (error) {
      console.error('Error finding tours by park:', error);
      throw error;
    }
  }

  static async findByAgency(agencyId) {
    try {
      const tours = await getRows(
        'SELECT * FROM tours WHERE agency_id = $1 ORDER BY created_at DESC',
        [agencyId]
      );
      return tours.map(tour => new Tour(tour));
    } catch (error) {
      console.error('Error finding tours by agency:', error);
      throw error;
    }
  }
}

module.exports = Tour;
