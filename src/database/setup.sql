-- ...existing code...

-- PostgreSQL schema for AI Safari backend
-- Creates core tables + indexes used by the Node API and ML service.

BEGIN;

-- Optional extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- schema_migrations
CREATE TABLE IF NOT EXISTS schema_migrations (
  version TEXT PRIMARY KEY,
  applied_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Parks
CREATE TABLE IF NOT EXISTS parks (
  id SERIAL PRIMARY KEY,
  slug TEXT UNIQUE,
  name TEXT NOT NULL,
  description TEXT,
  location JSONB,            -- geo info: { "lat":..., "lng":..., "bounds": ... }
  metadata JSONB,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_parks_slug ON parks (slug);
CREATE INDEX IF NOT EXISTS idx_parks_location_gin ON parks USING GIN (location);

-- Users (visitors / app users)
CREATE TABLE IF NOT EXISTS users (
  id SERIAL PRIMARY KEY,
  uuid UUID NOT NULL DEFAULT uuid_generate_v4(),
  email TEXT UNIQUE,
  name TEXT,
  preferences JSONB,         -- user preferences for recommendations
  metadata JSONB,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_users_uuid ON users (uuid);
CREATE INDEX IF NOT EXISTS idx_users_preferences_gin ON users USING GIN (preferences);

-- Wildlife predictions produced by ML service
CREATE TABLE IF NOT EXISTS wildlife_predictions (
  id BIGSERIAL PRIMARY KEY,
  park_id INTEGER REFERENCES parks(id) ON DELETE SET NULL,
  animal_type TEXT NOT NULL,
  predicted_at TIMESTAMP WITH TIME ZONE NOT NULL, -- when prediction applies
  score NUMERIC,                                 -- confidence / probability
  features JSONB,                                -- input features used for prediction
  prediction JSONB,                              -- raw model output
  metadata JSONB,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_wildlife_park ON wildlife_predictions (park_id);
CREATE INDEX IF NOT EXISTS idx_wildlife_predicted_at ON wildlife_predictions (predicted_at);
CREATE INDEX IF NOT EXISTS idx_wildlife_animal_type ON wildlife_predictions (animal_type);
CREATE INDEX IF NOT EXISTS idx_wildlife_prediction_gin ON wildlife_predictions USING GIN (prediction);

-- Routes (hiking / driving routes)
CREATE TABLE IF NOT EXISTS routes (
  id SERIAL PRIMARY KEY,
  park_id INTEGER REFERENCES parks(id) ON DELETE CASCADE,
  name TEXT,
  description TEXT,
  path JSONB,              -- GeoJSON or array of points
  stats JSONB,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_routes_park ON routes (park_id);
CREATE INDEX IF NOT EXISTS idx_routes_path_gin ON routes USING GIN (path);

-- Accommodations (lodging in/near parks)
CREATE TABLE IF NOT EXISTS accommodations (
  id SERIAL PRIMARY KEY,
  park_id INTEGER REFERENCES parks(id) ON DELETE SET NULL,
  name TEXT,
  type TEXT,               -- cabin / hotel / campsite etc.
  location JSONB,
  details JSONB,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_accommodations_park ON accommodations (park_id);
CREATE INDEX IF NOT EXISTS idx_accommodations_location_gin ON accommodations USING GIN (location);

-- Recommendations (served to users or quick park-level)
CREATE TABLE IF NOT EXISTS recommendations (
  id BIGSERIAL PRIMARY KEY,
  user_id INTEGER REFERENCES users(id) ON DELETE SET NULL,
  park_id INTEGER REFERENCES parks(id) ON DELETE SET NULL,
  type TEXT,               -- e.g., 'personalized', 'quick'
  payload JSONB,           -- recommendation payload / list
  metadata JSONB,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_recommendations_user ON recommendations (user_id);
CREATE INDEX IF NOT EXISTS idx_recommendations_park ON recommendations (park_id);
CREATE INDEX IF NOT EXISTS idx_recommendations_payload_gin ON recommendations USING GIN (payload);

-- Optional: lightweight audit log for DB ops (used by logger helpers)
CREATE TABLE IF NOT EXISTS db_audit_log (
  id BIGSERIAL PRIMARY KEY,
  service TEXT,
  operation TEXT,
  payload JSONB,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_db_audit_log_service ON db_audit_log (service);
CREATE INDEX IF NOT EXISTS idx_db_audit_log_payload_gin ON db_audit_log USING GIN (payload);

COMMIT;