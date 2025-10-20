const { getRows, getRow, execute } = require('../database/config');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');

// User model using raw PostgreSQL queries
class User {
  constructor(data) {
    this.id = data.id;
    this.email = data.email;
    this.password = data.password_hash || data.password; // Handle both column names
    this.name = data.name;
    this.phone = data.phone;
    this.role = data.role;
    this.avatar = data.avatar;
    this.isActive = data.is_active || data.isActive;
    this.isVerified = data.is_verified || data.isVerified;
    this.lastActive = data.last_active || data.lastActive;
    this.additionalData = data.additional_data || data.additionalData;
    this.createdAt = data.created_at || data.createdAt;
    this.updatedAt = data.updated_at || data.updatedAt;
  }

  // Instance methods
  async comparePassword(candidatePassword) {
    return await bcrypt.compare(candidatePassword, this.password);
  }

  generateAuthToken() {
    return jwt.sign(
      { 
        id: this.id,
        email: this.email,
        role: this.role 
      },
      process.env.JWT_SECRET,
      { expiresIn: process.env.JWT_EXPIRE || '7d' }
    );
  }

  getPublicProfile() {
    const userObject = { ...this };
    delete userObject.password;
    return userObject;
  }

  // Static methods
  static async findByEmail(email) {
    try {
      const user = await getRow(
        'SELECT * FROM users WHERE email = $1',
        [email.toLowerCase()]
      );
      return user ? new User(user) : null;
    } catch (error) {
      console.error('Error finding user by email:', error);
      throw error;
    }
  }

  static async findById(id) {
    try {
      const user = await getRow(
        'SELECT * FROM users WHERE id = $1',
        [id]
      );
      return user ? new User(user) : null;
    } catch (error) {
      console.error('Error finding user by ID:', error);
      throw error;
    }
  }

  static async findByRole(role) {
    try {
      const users = await getRows(
        'SELECT id, email, name, phone, role, avatar, is_active, is_verified, last_active, additional_data, created_at, updated_at FROM users WHERE role = $1 AND is_active = true',
        [role]
      );
      return users.map(user => new User(user));
    } catch (error) {
      console.error('Error finding users by role:', error);
      throw error;
    }
  }

  static async find(options = {}) {
    try {
      let query = 'SELECT * FROM users WHERE 1=1';
      const params = [];
      let paramCount = 0;

      if (options.isActive !== undefined) {
        paramCount++;
        query += ` AND is_active = $${paramCount}`;
        params.push(options.isActive);
      }

      if (options.limit) {
        paramCount++;
        query += ` LIMIT $${paramCount}`;
        params.push(options.limit);
      }

      if (options.offset) {
        paramCount++;
        query += ` OFFSET $${paramCount}`;
        params.push(options.offset);
      }

      query += ' ORDER BY created_at DESC';

      const users = await getRows(query, params);
      return users.map(user => new User(user));
    } catch (error) {
      console.error('Error finding users:', error);
      throw error;
    }
  }

  static async count(options = {}) {
    try {
      let query = 'SELECT COUNT(*) as count FROM users WHERE 1=1';
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
      console.error('Error counting users:', error);
      throw error;
    }
  }

  static async create(userData) {
    try {
      const { email, password, name, phone, role, additionalData = {} } = userData;
      
      // Hash password
      const salt = await bcrypt.genSalt(12);
      const hashedPassword = await bcrypt.hash(password, salt);

      const result = await execute(
        `INSERT INTO users (id, email, password_hash, name, phone, role, additional_data, is_active, is_verified, created_at, updated_at)
         VALUES (gen_random_uuid(), $1, $2, $3, $4, $5, $6, true, false, NOW(), NOW())
         RETURNING *`,
        [email.toLowerCase(), hashedPassword, name, phone, role, JSON.stringify(additionalData)]
      );

      return new User(result.rows[0]);
    } catch (error) {
      console.error('Error creating user:', error);
      throw error;
    }
  }

  async save() {
    try {
      if (this.id) {
        // Update existing user
        const result = await execute(
          `UPDATE users SET 
           email = $1, name = $2, phone = $3, role = $4, avatar = $5, 
           is_active = $6, is_verified = $7, additional_data = $8, 
           updated_at = NOW()
           WHERE id = $9
           RETURNING *`,
          [
            this.email, this.name, this.phone, this.role, this.avatar,
            this.isActive, this.isVerified, JSON.stringify(this.additionalData),
            this.id
          ]
        );
        return new User(result.rows[0]);
      } else {
        // Create new user
        return await User.create(this);
      }
    } catch (error) {
      console.error('Error saving user:', error);
      throw error;
    }
  }

  static async findByIdAndUpdate(id, updateData, options = {}) {
    try {
      const setClause = [];
      const params = [];
      let paramCount = 0;

      Object.keys(updateData).forEach(key => {
        if (key === 'additionalData') {
          paramCount++;
          setClause.push(`additional_data = $${paramCount}`);
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

      const query = `UPDATE users SET ${setClause.join(', ')} 
                     WHERE id = $${paramCount} 
                     RETURNING *`;

      const result = await execute(query, params);
      return result.rows[0] ? new User(result.rows[0]) : null;
    } catch (error) {
      console.error('Error updating user:', error);
      throw error;
    }
  }

  static async findByIdAndDelete(id) {
    try {
      const result = await execute(
        'UPDATE users SET is_active = false WHERE id = $1 RETURNING *',
        [id]
      );
      return result.rows[0] ? new User(result.rows[0]) : null;
    } catch (error) {
      console.error('Error deleting user:', error);
      throw error;
    }
  }

  static async aggregate(pipeline) {
    // This is a simplified implementation for basic aggregation
    // For complex aggregations, you might need to write raw SQL
    try {
      if (pipeline[0] && pipeline[0].$group) {
        const groupBy = pipeline[0].$group._id;
        const countField = Object.keys(pipeline[0].$group).find(key => key !== '_id');
        
        let query = `SELECT ${groupBy} as _id, COUNT(*) as count FROM users`;
        const params = [];

        if (groupBy === 'role') {
          query = `SELECT role as _id, COUNT(*) as count FROM users GROUP BY role`;
        }

        const result = await getRows(query, params);
        return result.map(row => ({
          _id: row._id,
          count: parseInt(row.count)
        }));
      }
      return [];
    } catch (error) {
      console.error('Error in aggregation:', error);
      return [];
    }
  }
}

module.exports = User;