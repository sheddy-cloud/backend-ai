BEGIN;

-- Create parks table
CREATE TABLE IF NOT EXISTS parks (
  id SERIAL PRIMARY KEY,
  park_id VARCHAR(50) UNIQUE NOT NULL,
  name VARCHAR(100) NOT NULL,
  description TEXT,
  location_lat DECIMAL(10, 8),
  location_lng DECIMAL(11, 8),
  image_url VARCHAR(255),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create wildlife_predictions table
CREATE TABLE IF NOT EXISTS wildlife_predictions (
  id SERIAL PRIMARY KEY,
  park_id VARCHAR(50) NOT NULL,
  animal_type VARCHAR(50) NOT NULL,
  probability DECIMAL(3, 2) NOT NULL,
  optimal_time VARCHAR(50),
  best_location VARCHAR(200),
  confidence DECIMAL(3, 2),
  tips TEXT,
  prediction_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  weather_conditions JSONB,
  FOREIGN KEY (park_id) REFERENCES parks(park_id) ON DELETE CASCADE
);

-- Create safari_routes table
CREATE TABLE IF NOT EXISTS safari_routes (
  id SERIAL PRIMARY KEY,
  route_id VARCHAR(50) UNIQUE NOT NULL,
  name VARCHAR(200) NOT NULL,
  description TEXT,
  duration VARCHAR(50),
  difficulty VARCHAR(50),
  best_time VARCHAR(100),
  estimated_cost VARCHAR(100),
  transportation VARCHAR(100),
  accommodation_type VARCHAR(100),
  score DECIMAL(3, 1),
  highlights JSONB,
  parks_included JSONB,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create accommodations table
CREATE TABLE IF NOT EXISTS accommodations (
  id SERIAL PRIMARY KEY,
  accommodation_id VARCHAR(50) UNIQUE NOT NULL,
  park_id VARCHAR(50) NOT NULL,
  name VARCHAR(200) NOT NULL,
  type VARCHAR(100),
  rating DECIMAL(2, 1),
  price VARCHAR(100),
  amenities JSONB,
  location VARCHAR(200),
  wildlife_viewing VARCHAR(100),
  photography_rating VARCHAR(100),
  family_friendly BOOLEAN DEFAULT true,
  score DECIMAL(3, 1),
  image_url VARCHAR(255),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (park_id) REFERENCES parks(park_id) ON DELETE CASCADE
);

-- Create user_preferences table
CREATE TABLE IF NOT EXISTS user_preferences (
  id SERIAL PRIMARY KEY,
  user_id VARCHAR(100) UNIQUE NOT NULL,
  preferences JSONB,
  visited_parks JSONB,
  ratings JSONB,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_wildlife_park_date ON wildlife_predictions(park_id, prediction_date);
CREATE INDEX IF NOT EXISTS idx_accommodations_park ON accommodations(park_id);
CREATE INDEX IF NOT EXISTS idx_routes_score ON safari_routes(score DESC);

-- Trigger function to update updated_at columns
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = CURRENT_TIMESTAMP;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Triggers
DROP TRIGGER IF EXISTS update_parks_updated_at ON parks;
CREATE TRIGGER update_parks_updated_at
  BEFORE UPDATE ON parks
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_user_preferences_updated_at ON user_preferences;
CREATE TRIGGER update_user_preferences_updated_at
  BEFORE UPDATE ON user_preferences
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

COMMIT;