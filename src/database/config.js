const { query } = require('../config/database');

// Helper function to get multiple rows
const getRows = async (sql, params = []) => {
  try {
    const result = await query(sql, params);
    return result.rows;
  } catch (error) {
    console.error('❌ Error executing getRows query:', error);
    throw error;
  }
};

// Helper function to get a single row
const getRow = async (sql, params = []) => {
  try {
    const result = await query(sql, params);
    return result.rows[0] || null;
  } catch (error) {
    console.error('❌ Error executing getRow query:', error);
    throw error;
  }
};

// Helper function to execute a query without returning data (INSERT, UPDATE, DELETE)
const execute = async (sql, params = []) => {
  try {
    const result = await query(sql, params);
    return result;
  } catch (error) {
    console.error('❌ Error executing query:', error);
    throw error;
  }
};

module.exports = {
  getRows,
  getRow,
  execute
};
