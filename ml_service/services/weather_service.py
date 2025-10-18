import asyncio
import aiohttp
import json
from datetime import datetime, timedelta
from typing import Dict, List, Optional
import os
from dotenv import load_dotenv
import redis.asyncio as redis
from loguru import logger

from models.prediction_models import WeatherData, WeatherCondition

load_dotenv()

class WeatherService:
    def __init__(self):
        self.api_key = os.getenv("OPENWEATHER_API_KEY")
        self.base_url = "http://api.openweathermap.org/data/2.5"
        self.redis_client = None
        self.parks_coordinates = {
            "serengeti": {"lat": -2.3333, "lon": 34.8333},
            "manyara": {"lat": -3.5000, "lon": 35.8333},
            "mikumi": {"lat": -7.1167, "lon": 37.0833},
            "gombe": {"lat": -4.6667, "lon": 29.6333}
        }
        self.cache_ttl = 1800  # 30 minutes cache
        
    async def initialize(self):
        """Initialize Redis connection"""
        try:
            self.redis_client = redis.Redis(
                host=os.getenv("REDIS_HOST", "localhost"),
                port=int(os.getenv("REDIS_PORT", 6379)),
                decode_responses=True
            )
            await self.redis_client.ping()
            logger.info("✅ Weather service Redis connection established")
        except Exception as e:
            logger.warning(f"⚠️ Redis connection failed, using API only: {e}")
            self.redis_client = None
    
    async def get_current_weather(self, park_id: str) -> WeatherData:
        """Get current weather for a specific park"""
        try:
            # Check cache first
            if self.redis_client:
                cached_weather = await self._get_cached_weather(park_id)
                if cached_weather:
                    logger.info(f"🌤️ Using cached weather data for {park_id}")
                    return cached_weather
            
            # Get fresh weather data
            weather_data = await self._fetch_weather_from_api(park_id)
            
            # Cache the result
            if self.redis_client:
                await self._cache_weather(park_id, weather_data)
            
            return weather_data
            
        except Exception as e:
            logger.error(f"❌ Error getting weather for {park_id}: {e}")
            # Return default weather data as fallback
            return self._get_default_weather(park_id)
    
    async def _fetch_weather_from_api(self, park_id: str) -> WeatherData:
        """Fetch weather data from OpenWeatherMap API"""
        if not self.api_key:
            logger.warning("⚠️ No OpenWeather API key found, using default weather")
            return self._get_default_weather(park_id)
        
        coords = self.parks_coordinates.get(park_id)
        if not coords:
            raise ValueError(f"Unknown park: {park_id}")
        
        async with aiohttp.ClientSession() as session:
            # Get current weather
            current_url = f"{self.base_url}/weather"
            params = {
                "lat": coords["lat"],
                "lon": coords["lon"],
                "appid": self.api_key,
                "units": "metric"
            }
            
            async with session.get(current_url, params=params) as response:
                if response.status == 200:
                    data = await response.json()
                    return self._parse_weather_data(data, park_id)
                else:
                    logger.error(f"❌ Weather API error: {response.status}")
                    return self._get_default_weather(park_id)
    
    def _parse_weather_data(self, api_data: Dict, park_id: str) -> WeatherData:
        """Parse OpenWeatherMap API response"""
        try:
            main = api_data.get("main", {})
            weather = api_data.get("weather", [{}])[0]
            wind = api_data.get("wind", {})
            clouds = api_data.get("clouds", {})
            
            # Map weather conditions
            condition_map = {
                "Clear": WeatherCondition.SUNNY,
                "Clouds": WeatherCondition.CLOUDY,
                "Rain": WeatherCondition.RAINY,
                "Drizzle": WeatherCondition.RAINY,
                "Thunderstorm": WeatherCondition.RAINY,
                "Snow": WeatherCondition.RAINY,
                "Mist": WeatherCondition.OVERCAST,
                "Fog": WeatherCondition.OVERCAST,
                "Haze": WeatherCondition.OVERCAST
            }
            
            weather_condition = condition_map.get(weather.get("main"), WeatherCondition.PARTLY_CLOUDY)
            
            # Calculate visibility (API doesn't always provide this)
            visibility = api_data.get("visibility", 10000) / 1000  # Convert to km
            
            # Calculate precipitation probability
            precipitation = 0.0
            if "rain" in api_data:
                precipitation = api_data["rain"].get("1h", 0.0)
            
            return WeatherData(
                temperature=main.get("temp", 25.0),
                humidity=main.get("humidity", 60.0),
                wind_speed=wind.get("speed", 0.0),
                precipitation=precipitation,
                condition=weather_condition,
                visibility=visibility,
                pressure=main.get("pressure", 1013.25),
                timestamp=datetime.now()
            )
            
        except Exception as e:
            logger.error(f"❌ Error parsing weather data: {e}")
            return self._get_default_weather(park_id)
    
    def _get_default_weather(self, park_id: str) -> WeatherData:
        """Get default weather data when API fails"""
        # Default weather based on park location and typical conditions
        default_conditions = {
            "serengeti": {"temp": 25.0, "humidity": 65.0, "condition": WeatherCondition.SUNNY},
            "manyara": {"temp": 28.0, "humidity": 70.0, "condition": WeatherCondition.PARTLY_CLOUDY},
            "mikumi": {"temp": 30.0, "humidity": 60.0, "condition": WeatherCondition.SUNNY},
            "gombe": {"temp": 26.0, "humidity": 80.0, "condition": WeatherCondition.CLOUDY}
        }
        
        default = default_conditions.get(park_id, {"temp": 25.0, "humidity": 65.0, "condition": WeatherCondition.SUNNY})
        
        return WeatherData(
            temperature=default["temp"],
            humidity=default["humidity"],
            wind_speed=5.0,
            precipitation=0.0,
            condition=default["condition"],
            visibility=10.0,
            pressure=1013.25,
            timestamp=datetime.now()
        )
    
    async def _get_cached_weather(self, park_id: str) -> Optional[WeatherData]:
        """Get weather data from cache"""
        try:
            if not self.redis_client:
                return None
                
            cache_key = f"weather:{park_id}"
            cached_data = await self.redis_client.get(cache_key)
            
            if cached_data:
                data = json.loads(cached_data)
                # Convert timestamp back to datetime
                data["timestamp"] = datetime.fromisoformat(data["timestamp"])
                return WeatherData(**data)
            
            return None
            
        except Exception as e:
            logger.error(f"❌ Error getting cached weather: {e}")
            return None
    
    async def _cache_weather(self, park_id: str, weather_data: WeatherData):
        """Cache weather data in Redis"""
        try:
            if not self.redis_client:
                return
                
            cache_key = f"weather:{park_id}"
            # Convert datetime to string for JSON serialization
            data_dict = weather_data.dict()
            data_dict["timestamp"] = weather_data.timestamp.isoformat()
            
            await self.redis_client.setex(
                cache_key,
                self.cache_ttl,
                json.dumps(data_dict)
            )
            
        except Exception as e:
            logger.error(f"❌ Error caching weather: {e}")
    
    async def sync_all_parks_weather(self):
        """Sync weather data for all parks"""
        logger.info("🌤️ Starting weather sync for all parks...")
        
        tasks = []
        for park_id in self.parks_coordinates.keys():
            task = asyncio.create_task(self._update_park_weather(park_id))
            tasks.append(task)
        
        await asyncio.gather(*tasks, return_exceptions=True)
        logger.info("✅ Weather sync completed for all parks")
    
    async def _update_park_weather(self, park_id: str):
        """Update weather for a specific park"""
        try:
            weather_data = await self._fetch_weather_from_api(park_id)
            if self.redis_client:
                await self._cache_weather(park_id, weather_data)
            logger.info(f"🌤️ Updated weather for {park_id}")
        except Exception as e:
            logger.error(f"❌ Error updating weather for {park_id}: {e}")
    
    async def get_weather_forecast(self, park_id: str, days: int = 5) -> List[WeatherData]:
        """Get weather forecast for a park (future enhancement)"""
        # This would integrate with OpenWeatherMap's forecast API
        # For now, return current weather repeated
        current_weather = await self.get_current_weather(park_id)
        forecast = []
        
        for i in range(days):
            forecast_weather = current_weather.copy()
            forecast_weather.timestamp = datetime.now() + timedelta(days=i)
            forecast.append(forecast_weather)
        
        return forecast
    
    def get_weather_impact_score(self, weather_data: WeatherData, animal_type: str) -> float:
        """Calculate weather impact on animal sighting probability"""
        # Weather impact factors for different animals
        weather_impacts = {
            "lions": {"sunny": 1.2, "cloudy": 1.0, "rainy": 0.7, "overcast": 0.9},
            "elephants": {"sunny": 1.0, "cloudy": 1.1, "rainy": 0.8, "overcast": 1.0},
            "cheetahs": {"sunny": 1.3, "cloudy": 1.0, "rainy": 0.6, "overcast": 0.9},
            "wildebeest": {"sunny": 1.0, "cloudy": 1.0, "rainy": 0.9, "overcast": 1.0},
            "zebras": {"sunny": 1.0, "cloudy": 1.0, "rainy": 0.8, "overcast": 1.0}
        }
        
        # Get base impact for animal type
        base_impact = weather_impacts.get(animal_type, {"sunny": 1.0, "cloudy": 1.0, "rainy": 0.8, "overcast": 1.0})
        
        # Get impact for current weather condition
        condition_impact = base_impact.get(weather_data.condition.value, 1.0)
        
        # Adjust for temperature extremes
        temp_factor = 1.0
        if weather_data.temperature > 35:  # Too hot
            temp_factor = 0.8
        elif weather_data.temperature < 15:  # Too cold
            temp_factor = 0.9
        
        # Adjust for heavy rain
        rain_factor = 1.0
        if weather_data.precipitation > 10:  # Heavy rain
            rain_factor = 0.7
        
        return condition_impact * temp_factor * rain_factor
