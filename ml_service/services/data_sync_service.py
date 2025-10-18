import asyncio
import json
import psycopg2
import psycopg2.extras
from datetime import datetime, timedelta
from typing import Dict, List, Optional, Any
import os
from dotenv import load_dotenv
import redis.asyncio as redis
from loguru import logger

load_dotenv()

class DataSyncService:
    def __init__(self):
        self.pg_connection = None
        self.redis_client = None
        self.sync_interval = 7200  # 2 hours
        self.last_sync = {}
        
    async def initialize(self):
        """Initialize the data sync service"""
        try:
            # Initialize PostgreSQL connection
            self.pg_connection = psycopg2.connect(
                host=os.getenv("DB_HOST", "localhost"),
                port=int(os.getenv("DB_PORT", 5432)),
                database=os.getenv("DB_NAME", "ai_safari_db"),
                user=os.getenv("DB_USER", "postgres"),
                password=os.getenv("DB_PASSWORD", "password")
            )
            logger.info("✅ Data sync service PostgreSQL connection established")
        except Exception as e:
            logger.warning(f"⚠️ PostgreSQL connection failed: {e}")
            self.pg_connection = None
        
        try:
            # Initialize Redis connection
            self.redis_client = redis.Redis(
                host=os.getenv("REDIS_HOST", "localhost"),
                port=int(os.getenv("REDIS_PORT", 6379)),
                decode_responses=True
            )
            await self.redis_client.ping()
            logger.info("✅ Data sync service Redis connection established")
        except Exception as e:
            logger.warning(f"⚠️ Redis connection failed: {e}")
            self.redis_client = None
        
        logger.info("✅ Data sync service initialized successfully")
    
    async def sync_all_data(self):
        """Sync all data between services"""
        try:
            logger.info("🔄 Starting comprehensive data sync...")
            
            # Sync wildlife predictions
            await self.sync_wildlife_predictions()
            
            # Sync park information
            await self.sync_park_data()
            
            # Sync user preferences
            await self.sync_user_preferences()
            
            # Sync recent sightings
            await self.sync_recent_sightings()
            
            # Update sync timestamp
            await self._update_sync_timestamp()
            
            logger.info("✅ Comprehensive data sync completed")
            
        except Exception as e:
            logger.error(f"❌ Error in comprehensive data sync: {e}")
    
    async def sync_wildlife_predictions(self):
        """Sync wildlife predictions from ML service to database"""
        try:
            if not self.pg_connection or not self.redis_client:
                logger.warning("⚠️ Database or Redis not available for wildlife sync")
                return
            
            # Get current ML predictions from Redis
            parks = ["serengeti", "manyara", "mikumi", "gombe"]
            
            for park_id in parks:
                cache_key = f"realtime_predictions:{park_id}"
                predictions_data = await self.redis_client.get(cache_key)
                
                if predictions_data:
                    predictions = json.loads(predictions_data)
                    await self._update_database_predictions(park_id, predictions)
                    logger.info(f"🔄 Synced wildlife predictions for {park_id}")
                else:
                    logger.info(f"ℹ️ No predictions data found for {park_id}")
            
        except Exception as e:
            logger.error(f"❌ Error syncing wildlife predictions: {e}")
    
    async def _update_database_predictions(self, park_id: str, predictions_data: Dict[str, Any]):
        """Update database with current ML predictions"""
        try:
            if not self.pg_connection:
                return
            
            cursor = self.pg_connection.cursor()
            
            # Get current timestamp
            current_time = datetime.now()
            
            for animal_type, prediction in predictions_data.get("predictions", {}).items():
                # Update or insert prediction
                update_query = """
                    INSERT INTO wildlife_predictions 
                    (park_id, animal_type, probability, optimal_time, best_location, 
                     confidence, tips, prediction_date, weather_conditions)
                    VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s)
                    ON CONFLICT (park_id, animal_type) 
                    DO UPDATE SET
                        probability = EXCLUDED.probability,
                        confidence = EXCLUDED.confidence,
                        prediction_date = EXCLUDED.prediction_date,
                        weather_conditions = EXCLUDED.weather_conditions
                """
                
                weather_conditions = {
                    "weather_factor": prediction.get("weather_factor", 1.0),
                    "seasonal_factor": prediction.get("seasonal_factor", 1.0),
                    "time_factor": prediction.get("time_factor", 1.0),
                    "last_updated": current_time.isoformat()
                }
                
                cursor.execute(update_query, (
                    park_id,
                    animal_type,
                    prediction.get("probability", 0.0),
                    prediction.get("optimalTime", "Unknown"),
                    prediction.get("bestLocation", "Unknown"),
                    prediction.get("confidence", 0.0),
                    prediction.get("tips", ""),
                    current_time,
                    json.dumps(weather_conditions)
                ))
            
            self.pg_connection.commit()
            cursor.close()
            
        except Exception as e:
            logger.error(f"❌ Error updating database predictions: {e}")
            if self.pg_connection:
                self.pg_connection.rollback()
    
    async def sync_park_data(self):
        """Sync park information from database to ML service"""
        try:
            if not self.pg_connection or not self.redis_client:
                return
            
            cursor = self.pg_connection.cursor(cursor_factory=psycopg2.extras.RealDictCursor)
            
            # Get park information
            cursor.execute("SELECT * FROM parks")
            parks = cursor.fetchall()
            
            # Cache park data in Redis
            for park in parks:
                park_key = f"park_info:{park['park_id']}"
                park_data = {
                    "park_id": park["park_id"],
                    "name": park["name"],
                    "description": park["description"],
                    "location_lat": float(park["location_lat"]) if park["location_lat"] else None,
                    "location_lng": float(park["location_lng"]) if park["location_lng"] else None,
                    "image_url": park["image_url"],
                    "last_synced": datetime.now().isoformat()
                }
                
                await self.redis_client.setex(
                    park_key,
                    86400,  # 24 hours
                    json.dumps(park_data)
                )
            
            cursor.close()
            logger.info(f"🔄 Synced data for {len(parks)} parks")
            
        except Exception as e:
            logger.error(f"❌ Error syncing park data: {e}")
    
    async def sync_user_preferences(self):
        """Sync user preferences from database"""
        try:
            if not self.pg_connection or not self.redis_client:
                return
            
            cursor = self.pg_connection.cursor(cursor_factory=psycopg2.extras.RealDictCursor)
            
            # Get user preferences
            cursor.execute("SELECT * FROM user_preferences")
            preferences = cursor.fetchall()
            
            # Cache user preferences in Redis
            for pref in preferences:
                pref_key = f"user_preferences:{pref['user_id']}"
                await self.redis_client.setex(
                    pref_key,
                    3600,  # 1 hour
                    json.dumps(pref)
                )
            
            cursor.close()
            logger.info(f"🔄 Synced preferences for {len(preferences)} users")
            
        except Exception as e:
            logger.error(f"❌ Error syncing user preferences: {e}")
    
    async def sync_recent_sightings(self):
        """Sync recent sightings from ML service to database"""
        try:
            if not self.pg_connection or not self.redis_client:
                return
            
            # This would typically involve creating a sightings table
            # For now, we'll just log the sync attempt
            logger.info("🔄 Recent sightings sync (sightings table not yet implemented)")
            
        except Exception as e:
            logger.error(f"❌ Error syncing recent sightings: {e}")
    
    async def get_sync_status(self) -> Dict[str, Any]:
        """Get current sync status"""
        try:
            status = {
                "last_sync": self.last_sync,
                "postgres_connected": self.pg_connection is not None,
                "redis_connected": self.redis_client is not None,
                "timestamp": datetime.now().isoformat()
            }
            
            if self.redis_client:
                # Get last sync timestamp from Redis
                last_sync_data = await self.redis_client.get("last_sync_timestamp")
                if last_sync_data:
                    status["redis_last_sync"] = last_sync_data
            
            return status
            
        except Exception as e:
            logger.error(f"❌ Error getting sync status: {e}")
            return {"error": str(e)}
    
    async def _update_sync_timestamp(self):
        """Update the last sync timestamp"""
        try:
            current_time = datetime.now().isoformat()
            self.last_sync["comprehensive"] = current_time
            
            if self.redis_client:
                await self.redis_client.setex(
                    "last_sync_timestamp",
                    86400,  # 24 hours
                    current_time
                )
            
        except Exception as e:
            logger.error(f"❌ Error updating sync timestamp: {e}")
    
    async def force_sync_park(self, park_id: str):
        """Force sync data for a specific park"""
        try:
            logger.info(f"🔄 Force syncing data for {park_id}")
            
            # Sync wildlife predictions for specific park
            await self.sync_wildlife_predictions()
            
            # Sync park data
            await self.sync_park_data()
            
            logger.info(f"✅ Force sync completed for {park_id}")
            
        except Exception as e:
            logger.error(f"❌ Error in force sync for {park_id}: {e}")
    
    async def get_database_stats(self) -> Dict[str, Any]:
        """Get database statistics"""
        try:
            if not self.pg_connection:
                return {"error": "PostgreSQL not connected"}
            
            cursor = self.pg_connection.cursor()
            
            # Get table row counts
            tables = ["parks", "wildlife_predictions", "safari_routes", "accommodations", "user_preferences"]
            stats = {}
            
            for table in tables:
                try:
                    cursor.execute(f"SELECT COUNT(*) FROM {table}")
                    count = cursor.fetchone()[0]
                    stats[f"{table}_count"] = count
                except Exception as e:
                    stats[f"{table}_count"] = f"Error: {e}"
            
            cursor.close()
            
            return {
                "database_stats": stats,
                "timestamp": datetime.now().isoformat()
            }
            
        except Exception as e:
            logger.error(f"❌ Error getting database stats: {e}")
            return {"error": str(e)}
    
    async def cleanup_old_sync_data(self):
        """Clean up old sync data"""
        try:
            if not self.redis_client:
                return
            
            # Clean up old sync timestamps
            keys_to_clean = await self.redis_client.keys("last_sync_*")
            for key in keys_to_clean:
                # Check if key is older than 7 days
                ttl = await self.redis_client.ttl(key)
                if ttl == -1:  # No expiration set
                    await self.redis_client.expire(key, 604800)  # 7 days
            
            logger.info("🧹 Cleaned up old sync data")
            
        except Exception as e:
            logger.error(f"❌ Error cleaning up sync data: {e}")
    
    async def close_connections(self):
        """Close database connections"""
        try:
            if self.pg_connection:
                self.pg_connection.close()
                logger.info("✅ PostgreSQL connection closed")
            
            if self.redis_client:
                await self.redis_client.close()
                logger.info("✅ Redis connection closed")
                
        except Exception as e:
            logger.error(f"❌ Error closing connections: {e}")
