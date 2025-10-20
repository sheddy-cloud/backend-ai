const { getRows, getRow, execute } = require('../database/config');

// Booking model using raw PostgreSQL queries
class Booking {
  constructor(data) {
    this.id = data.id;
    this.userId = data.userId;
    this.tourId = data.tourId;
    this.status = data.status;
    this.bookingDate = data.bookingDate;
    this.travelDate = data.travelDate;
    this.guests = data.guests;
    this.totalAmount = data.totalAmount;
    this.createdAt = data.createdAt;
    this.updatedAt = data.updatedAt;
  }

  static async find(options = {}) {
    try {
      let query = 'SELECT * FROM bookings';
      const params = [];
      let paramCount = 0;

      if (options.userId) {
        paramCount++;
        query += ` AND user_id = $${paramCount}`;
        params.push(options.userId);
      }

      if (options.status) {
        paramCount++;
        query += ` AND status = $${paramCount}`;
        params.push(options.status);
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

      const bookings = await getRows(query, params);
      return bookings.map(booking => new Booking(booking));
    } catch (error) {
      console.error('Error finding bookings:', error);
      throw error;
    }
  }

  static async findById(id) {
    try {
      const booking = await getRow(
        'SELECT * FROM bookings WHERE id = $1',
        [id]
      );
      return booking ? new Booking(booking) : null;
    } catch (error) {
      console.error('Error finding booking by ID:', error);
      throw error;
    }
  }

  static async create(bookingData) {
    try {
      const result = await execute(
        `INSERT INTO bookings (id, user_id, tour_id, status, booking_date, travel_date, guests, total_amount, created_at, updated_at)
         VALUES (gen_random_uuid(), $1, $2, $3, $4, $5, $6, $7, NOW(), NOW())
         RETURNING *`,
        [bookingData.userId, bookingData.tourId, bookingData.status, bookingData.bookingDate, bookingData.travelDate, bookingData.guests, bookingData.totalAmount]
      );
      return new Booking(result.rows[0]);
    } catch (error) {
      console.error('Error creating booking:', error);
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

      const query = `UPDATE bookings SET ${setClause.join(', ')} 
                     WHERE id = $${paramCount} 
                     RETURNING *`;

      const result = await execute(query, params);
      return result.rows[0] ? new Booking(result.rows[0]) : null;
    } catch (error) {
      console.error('Error updating booking:', error);
      throw error;
    }
  }
}

module.exports = Booking;
