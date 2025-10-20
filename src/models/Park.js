const { getRows, getRow, execute } = require('../database/config');

// Park model using raw PostgreSQL queries
class Park {
  constructor(data) {
    this.id = data.id;
    this.name = data.name;
    this.description = data.description;
    this.location = data.location;
    this.wildlife = data.wildlife;
    this.rating = data.rating;
    this.isActive = data.isActive;
    this.createdAt = data.createdAt;
    this.updatedAt = data.updatedAt;
  }

  static async find(options = {}) {
    try {
      let query = 'SELECT * FROM parks WHERE 1=1';
      const params = [];
      let paramCount = 0;

      if (options.isActive !== undefined) {
        paramCount++;
        query += ` AND is_active = $${paramCount}`;
        params.push(options.isActive);
      }

      if (options.location) {
        paramCount++;
        query += ` AND location ILIKE $${paramCount}`;
        params.push(`%${options.location}%`);
      }

      if (options.search) {
        paramCount++;
        query += ` AND (name ILIKE $${paramCount} OR description ILIKE $${paramCount} OR wildlife ILIKE $${paramCount})`;
        params.push(`%${options.search}%`);
      }

      // Order by a valid column; fall back to name
      query += ' ORDER BY name ASC';

      if (options.limit) {
        paramCount++;
        query += ` LIMIT $${paramCount}`;
        params.push(options.limit);
      }

      const offset = options.skip ?? options.offset;
      if (offset) {
        paramCount++;
        query += ` OFFSET $${paramCount}`;
        params.push(offset);
      }

      const parks = await getRows(query, params);
      return parks.map(park => new Park(park));
    } catch (error) {
      console.error('Error finding parks:', error);
      throw error;
    }
  }

  static async findById(id) {
    try {
      const park = await getRow(
        'SELECT * FROM parks WHERE id = $1',
        [id]
      );
      return park ? new Park(park) : null;
    } catch (error) {
      console.error('Error finding park by ID:', error);
      throw error;
    }
  }

  static async count(options = {}) {
    try {
      let query = 'SELECT COUNT(*) as count FROM parks WHERE 1=1';
      const params = [];
      let paramCount = 0;

      if (options.isActive !== undefined) {
        paramCount++;
        query += ` AND is_active = $${paramCount}`;
        params.push(options.isActive);
      }

      const result = await getRow(query, params);
      return parseInt(result.count);
    } catch (error) {
      console.error('Error counting parks:', error);
      throw error;
    }
  }

  static async create(parkData) {
    try {
      const result = await execute(
        `INSERT INTO parks (id, name, description, location, wildlife, rating, is_active, created_at, updated_at)
         VALUES (gen_random_uuid(), $1, $2, $3, $4, $5, true, NOW(), NOW())
         RETURNING *`,
        [parkData.name, parkData.description, parkData.location, parkData.wildlife, parkData.rating]
      );
      return new Park(result.rows[0]);
    } catch (error) {
      console.error('Error creating park:', error);
      throw error;
    }
  }

  static async findByIdAndUpdate(id, updateData, options = {}) {
    try {
      const setClause = [];
      const params = [];
      let paramCount = 0;

      Object.keys(updateData).forEach(key => {
        paramCount++;
        setClause.push(`${key} = $${paramCount}`);
        params.push(updateData[key]);
      });

      paramCount++;
      setClause.push(`updated_at = NOW()`);
      paramCount++;
      params.push(id);

      const query = `UPDATE parks SET ${setClause.join(', ')} 
                     WHERE id = $${paramCount} 
                     RETURNING *`;

      const result = await execute(query, params);
      return result.rows[0] ? new Park(result.rows[0]) : null;
    } catch (error) {
      console.error('Error updating park:', error);
      throw error;
    }
  }

  static async findByLocation(location) {
    try {
      const parks = await getRows(
        'SELECT * FROM parks WHERE location ILIKE $1',
        [`%${location}%`]
      );
      return parks.map(park => new Park(park));
    } catch (error) {
      console.error('Error finding parks by location:', error);
      throw error;
    }
  }

  static async findNearby(latitude, longitude, maxDistance = 100) {
    try {
      // This is a simplified implementation
      // For production, you'd want to use PostGIS for proper geographic queries
      const parks = await getRows(
        'SELECT *, (6371 * acos(cos(radians($1)) * cos(radians(latitude)) * cos(radians(longitude) - radians($2)) + sin(radians($1)) * sin(radians(latitude)))) AS distance FROM parks HAVING distance < $3 ORDER BY distance',
        [latitude, longitude, maxDistance]
      );
      return parks.map(park => new Park(park));
    } catch (error) {
      console.error('Error finding nearby parks:', error);
      return [];
    }
  }
}

module.exports = Park;
