import asyncio
import json
from datetime import datetime, timedelta
from typing import Dict, List, Optional, Any
import os
from dotenv import load_dotenv
import redis.asyncio as redis
from loguru import logger

from models.prediction_models import AnimalPrediction, RealTimeUpdate

load_dotenv()

class RealTimeService:
    def __init__(self):
        self.redis_client = None
        self.active_connections = {}
        self.update_callbacks = {}
        
    async def initialize(self):
        """Initialize the real-time service"""
        try:
            # Initialize Redis connection
            self.redis_client = redis.Redis(
                host=os.getenv("REDIS_HOST", "localhost"),
                port=int(os.getenv("REDIS_PORT", 6379)),
                decode_responses=True
            )
            await self.redis_client.ping()
            logger.info("✅ Real-time service Redis connection established")
        except Exception as e:
            logger.warning(f"⚠️ Redis connection failed: {e}")
            self.redis_client = None
        
        logger.info("✅ Real-time service initialized successfully")
    
    async def update_predictions(self, park_id: str, predictions: Dict[str, AnimalPrediction]):
        """Update real-time predictions for a park"""
        try:
            if not self.redis_client:
                return
            
            # Cache current predictions
            cache_key = f"realtime_predictions:{park_id}"
            predictions_dict = {}
            
            for animal_type, pred in predictions.items():
                pred_dict = pred.dict()
                if pred_dict.get("last_seen"):
                    pred_dict["last_seen"] = pred_dict["last_seen"].isoformat()
                predictions_dict[animal_type] = pred_dict
            
            # Store with timestamp
            realtime_data = {
                "predictions": predictions_dict,
                "last_updated": datetime.now().isoformat(),
                "park_id": park_id
            }
            
            await self.redis_client.setex(
                cache_key,
                7200,  # 2 hours cache
                json.dumps(realtime_data)
            )
            
            # Notify active connections
            await self._notify_connections(park_id, realtime_data)
            
            logger.info(f"🔄 Updated real-time predictions for {park_id}")
            
        except Exception as e:
            logger.error(f"❌ Error updating real-time predictions: {e}")
    
    async def get_current_predictions(self, park_id: str) -> Dict[str, Any]:
        """Get current real-time predictions for a park"""
        try:
            if not self.redis_client:
                return {}
            
            cache_key = f"realtime_predictions:{park_id}"
            cached_data = await self.redis_client.get(cache_key)
            
            if cached_data:
                data = json.loads(cached_data)
                return data
            else:
                return {
                    "park_id": park_id,
                    "predictions": {},
                    "last_updated": datetime.now().isoformat(),
                    "message": "No real-time data available"
                }
                
        except Exception as e:
            logger.error(f"❌ Error getting real-time predictions: {e}")
            return {
                "park_id": park_id,
                "predictions": {},
                "last_updated": datetime.now().isoformat(),
                "error": str(e)
            }
    
    async def report_sighting(self, sighting: RealTimeUpdate):
        """Report a new wildlife sighting"""
        try:
            if not self.redis_client:
                return
            
            # Store sighting in Redis
            sighting_key = f"sighting:{sighting.park_id}:{sighting.animal_type}:{datetime.now().timestamp()}"
            sighting_dict = sighting.dict()
            sighting_dict["sighting_time"] = sighting.sighting_time.isoformat()
            
            await self.redis_client.setex(
                sighting_key,
                86400,  # 24 hours cache
                json.dumps(sighting_dict)
            )
            
            # Update recent sightings count
            await self._update_sighting_count(sighting.park_id, sighting.animal_type)
            
            # Notify connections about new sighting
            await self._notify_sighting(sighting)
            
            logger.info(f"🦁 New sighting reported: {sighting.animal_type} in {sighting.park_id}")
            
        except Exception as e:
            logger.error(f"❌ Error reporting sighting: {e}")
    
    async def _update_sighting_count(self, park_id: str, animal_type: str):
        """Update the count of recent sightings for an animal"""
        try:
            count_key = f"sighting_count:{park_id}:{animal_type}"
            current_count = await self.redis_client.get(count_key)
            
            if current_count:
                new_count = int(current_count) + 1
            else:
                new_count = 1
            
            # Store count with 24-hour expiry
            await self.redis_client.setex(count_key, 86400, str(new_count))
            
        except Exception as e:
            logger.error(f"❌ Error updating sighting count: {e}")
    
    async def get_recent_sightings(self, park_id: str, hours: int = 24) -> List[RealTimeUpdate]:
        """Get recent sightings for a park"""
        try:
            if not self.redis_client:
                return []
            
            # Get all sighting keys for the park
            pattern = f"sighting:{park_id}:*"
            keys = await self.redis_client.keys(pattern)
            
            sightings = []
            cutoff_time = datetime.now() - timedelta(hours=hours)
            
            for key in keys:
                sighting_data = await self.redis_client.get(key)
                if sighting_data:
                    sighting_dict = json.loads(sighting_data)
                    sighting_time = datetime.fromisoformat(sighting_dict["sighting_time"])
                    
                    if sighting_time >= cutoff_time:
                        sighting = RealTimeUpdate(**sighting_dict)
                        sightings.append(sighting)
            
            # Sort by sighting time (most recent first)
            sightings.sort(key=lambda x: x.sighting_time, reverse=True)
            
            return sightings
            
        except Exception as e:
            logger.error(f"❌ Error getting recent sightings: {e}")
            return []
    
    async def subscribe_to_updates(self, park_id: str, callback):
        """Subscribe to real-time updates for a park"""
        try:
            if park_id not in self.update_callbacks:
                self.update_callbacks[park_id] = []
            
            self.update_callbacks[park_id].append(callback)
            logger.info(f"📡 New subscription to updates for {park_id}")
            
        except Exception as e:
            logger.error(f"❌ Error subscribing to updates: {e}")
    
    async def unsubscribe_from_updates(self, park_id: str, callback):
        """Unsubscribe from real-time updates for a park"""
        try:
            if park_id in self.update_callbacks:
                if callback in self.update_callbacks[park_id]:
                    self.update_callbacks[park_id].remove(callback)
                    logger.info(f"📡 Unsubscribed from updates for {park_id}")
            
        except Exception as e:
            logger.error(f"❌ Error unsubscribing from updates: {e}")
    
    async def _notify_connections(self, park_id: str, data: Dict[str, Any]):
        """Notify all active connections about updates"""
        try:
            if park_id in self.update_callbacks:
                for callback in self.update_callbacks[park_id]:
                    try:
                        await callback(data)
                    except Exception as e:
                        logger.error(f"❌ Error in update callback: {e}")
                        
        except Exception as e:
            logger.error(f"❌ Error notifying connections: {e}")
    
    async def _notify_sighting(self, sighting: RealTimeUpdate):
        """Notify connections about new sighting"""
        try:
            notification_data = {
                "type": "new_sighting",
                "data": sighting.dict(),
                "timestamp": datetime.now().isoformat()
            }
            
            if sighting.park_id in self.update_callbacks:
                for callback in self.update_callbacks[sighting.park_id]:
                    try:
                        await callback(notification_data)
                    except Exception as e:
                        logger.error(f"❌ Error in sighting callback: {e}")
                        
        except Exception as e:
            logger.error(f"❌ Error notifying about sighting: {e}")
    
    async def get_park_status(self, park_id: str) -> Dict[str, Any]:
        """Get overall status of a park"""
        try:
            # Get current predictions
            predictions = await self.get_current_predictions(park_id)
            
            # Get recent sightings
            recent_sightings = await self.get_recent_sightings(park_id, hours=6)
            
            # Calculate activity level
            activity_level = self._calculate_activity_level(recent_sightings)
            
            return {
                "park_id": park_id,
                "status": "active",
                "activity_level": activity_level,
                "last_updated": predictions.get("last_updated", datetime.now().isoformat()),
                "recent_sightings_count": len(recent_sightings),
                "predictions_available": len(predictions.get("predictions", {})) > 0
            }
            
        except Exception as e:
            logger.error(f"❌ Error getting park status: {e}")
            return {
                "park_id": park_id,
                "status": "error",
                "error": str(e)
            }
    
    def _calculate_activity_level(self, sightings: List[RealTimeUpdate]) -> str:
        """Calculate activity level based on recent sightings"""
        if not sightings:
            return "low"
        
        recent_count = len(sightings)
        
        if recent_count >= 10:
            return "very_high"
        elif recent_count >= 6:
            return "high"
        elif recent_count >= 3:
            return "medium"
        else:
            return "low"
    
    async def cleanup_old_data(self):
        """Clean up old sighting data"""
        try:
            if not self.redis_client:
                return
            
            # This would typically be called periodically to clean up old data
            # For now, Redis TTL handles expiration automatically
            
            logger.info("🧹 Cleanup completed (handled by Redis TTL)")
            
        except Exception as e:
            logger.error(f"❌ Error during cleanup: {e}")
    
    async def get_system_stats(self) -> Dict[str, Any]:
        """Get system statistics"""
        try:
            if not self.redis_client:
                return {"error": "Redis not available"}
            
            # Get active subscriptions
            total_subscriptions = sum(len(callbacks) for callbacks in self.update_callbacks.values())
            
            # Get Redis info
            redis_info = await self.redis_client.info()
            
            return {
                "active_subscriptions": total_subscriptions,
                "parks_with_subscriptions": len(self.update_callbacks),
                "redis_connected": True,
                "redis_memory_usage": redis_info.get("used_memory_human", "N/A"),
                "redis_uptime": redis_info.get("uptime_in_seconds", 0),
                "timestamp": datetime.now().isoformat()
            }
            
        except Exception as e:
            logger.error(f"❌ Error getting system stats: {e}")
            return {"error": str(e)}
