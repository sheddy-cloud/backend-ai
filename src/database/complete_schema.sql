-- NAPASA Complete Database Schema
-- This defines all relations between tables

BEGIN;

-- ==============================================
-- CORE TABLES
-- ==============================================

-- Users table (base for all user types)
CREATE TABLE IF NOT EXISTS users (
  id VARCHAR(50) PRIMARY KEY,
  email VARCHAR(255) UNIQUE NOT NULL,
  password_hash VARCHAR(255) NOT NULL,
  name VARCHAR(255) NOT NULL,
  phone VARCHAR(20) NOT NULL,
  role VARCHAR(50) NOT NULL CHECK (role IN ('Tourist', 'Travel Agency', 'Lodge Owner', 'Restaurant Owner', 'Travel Gear Seller', 'Photographer', 'Tour Guide')),
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  last_active TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  additional_data JSONB -- Role-specific data stored as JSON
);

-- Parks table
CREATE TABLE IF NOT EXISTS parks (
  id VARCHAR(50) PRIMARY KEY,
  name VARCHAR(255) NOT NULL,
  description TEXT,
  location VARCHAR(255) NOT NULL,
  image_path VARCHAR(500),
  video_path VARCHAR(500),
  area_km2 DECIMAL(10, 2),
  established_year INTEGER,
  wildlife TEXT, -- Comma-separated list
  best_time_to_visit VARCHAR(100),
  entry_fee_usd DECIMAL(10, 2),
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ==============================================
-- RELATIONSHIP TABLES
-- ==============================================

-- Travel Agencies table (extends users)
CREATE TABLE IF NOT EXISTS travel_agencies (
  id VARCHAR(50) PRIMARY KEY,
  user_id VARCHAR(50) NOT NULL,
  company_name VARCHAR(255) NOT NULL,
  location VARCHAR(255) NOT NULL,
  certifications TEXT[], -- Array of certifications
  contact_email VARCHAR(255) NOT NULL,
  contact_phone VARCHAR(20) NOT NULL,
  website VARCHAR(255),
  description TEXT,
  rating DECIMAL(3, 2) DEFAULT 0.0,
  total_reviews INTEGER DEFAULT 0,
  is_verified BOOLEAN DEFAULT false,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- Lodges table
CREATE TABLE IF NOT EXISTS lodges (
  id VARCHAR(50) PRIMARY KEY,
  name VARCHAR(255) NOT NULL,
  location VARCHAR(255) NOT NULL,
  park_id VARCHAR(50), -- Can be null for lodges outside parks
  lodge_type VARCHAR(100) NOT NULL,
  capacity INTEGER NOT NULL,
  price_per_night_usd DECIMAL(10, 2) NOT NULL,
  amenities TEXT[], -- Array of amenities
  description TEXT,
  image_path VARCHAR(500),
  contact_email VARCHAR(255),
  contact_phone VARCHAR(20),
  rating DECIMAL(3, 2) DEFAULT 0.0,
  total_reviews INTEGER DEFAULT 0,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (park_id) REFERENCES parks(id) ON DELETE SET NULL
);

-- Tours table
CREATE TABLE IF NOT EXISTS tours (
  id VARCHAR(50) PRIMARY KEY,
  title VARCHAR(255) NOT NULL,
  description TEXT,
  park_id VARCHAR(50) NOT NULL,
  agency_id VARCHAR(50) NOT NULL,
  duration_days INTEGER NOT NULL,
  price_usd DECIMAL(10, 2) NOT NULL,
  max_participants INTEGER NOT NULL,
  difficulty_level VARCHAR(50) NOT NULL,
  includes TEXT, -- What's included
  excludes TEXT, -- What's excluded
  itinerary TEXT, -- Day-by-day itinerary
  image_path VARCHAR(500),
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (park_id) REFERENCES parks(id) ON DELETE CASCADE,
  FOREIGN KEY (agency_id) REFERENCES travel_agencies(id) ON DELETE CASCADE
);

-- Rooms table (belongs to lodges)
CREATE TABLE IF NOT EXISTS rooms (
  id VARCHAR(50) PRIMARY KEY,
  lodge_id VARCHAR(50) NOT NULL,
  room_type VARCHAR(100) NOT NULL,
  room_number VARCHAR(50) NOT NULL,
  capacity INTEGER NOT NULL,
  price_per_night_usd DECIMAL(10, 2) NOT NULL,
  amenities TEXT[], -- Array of room amenities
  is_available BOOLEAN DEFAULT true,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (lodge_id) REFERENCES lodges(id) ON DELETE CASCADE,
  UNIQUE(lodge_id, room_number) -- Unique room number per lodge
);

-- ==============================================
-- TRANSACTION TABLES
-- ==============================================

-- Bookings table
CREATE TABLE IF NOT EXISTS bookings (
  id VARCHAR(50) PRIMARY KEY,
  user_id VARCHAR(50) NOT NULL,
  booking_type VARCHAR(50) NOT NULL CHECK (booking_type IN ('tour', 'lodge', 'restaurant', 'travel_gear')),
  entity_id VARCHAR(50) NOT NULL, -- ID of the booked item
  entity_type VARCHAR(50) NOT NULL, -- Type of the booked item
  check_in_date TIMESTAMP,
  check_out_date TIMESTAMP,
  participants INTEGER DEFAULT 1,
  total_amount_usd DECIMAL(10, 2) NOT NULL,
  status VARCHAR(50) DEFAULT 'pending' CHECK (status IN ('pending', 'confirmed', 'cancelled', 'completed', 'refunded')),
  payment_status VARCHAR(50) DEFAULT 'pending' CHECK (payment_status IN ('pending', 'paid', 'failed', 'refunded')),
  special_requests TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- Reviews table
CREATE TABLE IF NOT EXISTS reviews (
  id VARCHAR(50) PRIMARY KEY,
  user_id VARCHAR(50) NOT NULL,
  entity_id VARCHAR(50) NOT NULL, -- ID of the reviewed item
  entity_type VARCHAR(50) NOT NULL, -- Type of the reviewed item
  rating INTEGER NOT NULL CHECK (rating >= 1 AND rating <= 5),
  title VARCHAR(255),
  comment TEXT,
  is_verified BOOLEAN DEFAULT false,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- ==============================================
-- SUPPORTING TABLES
-- ==============================================

-- Guides table
CREATE TABLE IF NOT EXISTS guides (
  id VARCHAR(50) PRIMARY KEY,
  name VARCHAR(255) NOT NULL,
  agency_id VARCHAR(50), -- Can be null for independent guides
  languages TEXT[] NOT NULL, -- Array of languages spoken
  experience_years INTEGER NOT NULL,
  specialties TEXT[], -- Array of specialties
  certifications TEXT[], -- Array of certifications
  contact_phone VARCHAR(20) NOT NULL,
  email VARCHAR(255),
  rating DECIMAL(3, 2) DEFAULT 0.0,
  total_reviews INTEGER DEFAULT 0,
  is_available BOOLEAN DEFAULT true,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (agency_id) REFERENCES travel_agencies(id) ON DELETE SET NULL
);

-- Restaurants table
CREATE TABLE IF NOT EXISTS restaurants (
  id VARCHAR(50) PRIMARY KEY,
  name VARCHAR(255) NOT NULL,
  location VARCHAR(255) NOT NULL,
  park_id VARCHAR(50), -- Can be null for restaurants outside parks
  cuisine_type VARCHAR(100) NOT NULL,
  price_range VARCHAR(50) NOT NULL,
  description TEXT,
  image_path VARCHAR(500),
  contact_phone VARCHAR(20),
  opening_hours VARCHAR(255),
  rating DECIMAL(3, 2) DEFAULT 0.0,
  total_reviews INTEGER DEFAULT 0,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (park_id) REFERENCES parks(id) ON DELETE SET NULL
);

-- Travel Gear table
CREATE TABLE IF NOT EXISTS travel_gear (
  id VARCHAR(50) PRIMARY KEY,
  name VARCHAR(255) NOT NULL,
  category VARCHAR(100) NOT NULL,
  description TEXT,
  price_usd DECIMAL(10, 2) NOT NULL,
  brand VARCHAR(100),
  image_path VARCHAR(500),
  specifications JSONB, -- Technical specifications
  availability INTEGER DEFAULT 1, -- Stock count
  seller_id VARCHAR(50), -- Can be null for admin items
  rating DECIMAL(3, 2) DEFAULT 0.0,
  total_reviews INTEGER DEFAULT 0,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (seller_id) REFERENCES users(id) ON DELETE SET NULL
);

-- ==============================================
-- INDEXES FOR PERFORMANCE
-- ==============================================

-- User indexes
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_users_role ON users(role);
CREATE INDEX IF NOT EXISTS idx_users_active ON users(is_active);

-- Park indexes
CREATE INDEX IF NOT EXISTS idx_parks_location ON parks(location);
CREATE INDEX IF NOT EXISTS idx_parks_active ON parks(is_active);

-- Tour indexes
CREATE INDEX IF NOT EXISTS idx_tours_park ON tours(park_id);
CREATE INDEX IF NOT EXISTS idx_tours_agency ON tours(agency_id);
CREATE INDEX IF NOT EXISTS idx_tours_active ON tours(is_active);

-- Booking indexes
CREATE INDEX IF NOT EXISTS idx_bookings_user ON bookings(user_id);
CREATE INDEX IF NOT EXISTS idx_bookings_entity ON bookings(entity_id, entity_type);
CREATE INDEX IF NOT EXISTS idx_bookings_status ON bookings(status);
CREATE INDEX IF NOT EXISTS idx_bookings_dates ON bookings(check_in_date, check_out_date);

-- Review indexes
CREATE INDEX IF NOT EXISTS idx_reviews_user ON reviews(user_id);
CREATE INDEX IF NOT EXISTS idx_reviews_entity ON reviews(entity_id, entity_type);
CREATE INDEX IF NOT EXISTS idx_reviews_rating ON reviews(rating);

-- Lodge indexes
CREATE INDEX IF NOT EXISTS idx_lodges_park ON lodges(park_id);
CREATE INDEX IF NOT EXISTS idx_lodges_location ON lodges(location);
CREATE INDEX IF NOT EXISTS idx_lodges_active ON lodges(is_active);

-- Room indexes
CREATE INDEX IF NOT EXISTS idx_rooms_lodge ON rooms(lodge_id);
CREATE INDEX IF NOT EXISTS idx_rooms_available ON rooms(is_available);

-- ==============================================
-- TRIGGERS FOR AUTOMATIC UPDATES
-- ==============================================

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = CURRENT_TIMESTAMP;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply triggers to all tables with updated_at
CREATE TRIGGER update_users_updated_at
  BEFORE UPDATE ON users
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_parks_updated_at
  BEFORE UPDATE ON parks
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_travel_agencies_updated_at
  BEFORE UPDATE ON travel_agencies
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_lodges_updated_at
  BEFORE UPDATE ON lodges
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_tours_updated_at
  BEFORE UPDATE ON tours
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_rooms_updated_at
  BEFORE UPDATE ON rooms
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_bookings_updated_at
  BEFORE UPDATE ON bookings
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_reviews_updated_at
  BEFORE UPDATE ON reviews
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_guides_updated_at
  BEFORE UPDATE ON guides
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_restaurants_updated_at
  BEFORE UPDATE ON restaurants
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_travel_gear_updated_at
  BEFORE UPDATE ON travel_gear
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

COMMIT;
