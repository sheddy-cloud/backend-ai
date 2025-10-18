from pydantic import BaseModel, Field
from typing import Dict, List, Optional, Any
from datetime import datetime
from enum import Enum

class Season(str, Enum):
    DRY = "dry"
    WET = "wet"
    TRANSITION = "transition"

class TimeOfDay(str, Enum):
    EARLY_MORNING = "early_morning"  # 06:00 - 09:00
    MORNING = "morning"              # 09:00 - 12:00
    AFTERNOON = "afternoon"          # 12:00 - 15:00
    LATE_AFTERNOON = "late_afternoon" # 15:00 - 18:00
    EVENING = "evening"              # 18:00 - 21:00
    NIGHT = "night"                  # 21:00 - 06:00

class WeatherCondition(str, Enum):
    SUNNY = "sunny"
    CLOUDY = "cloudy"
    RAINY = "rainy"
    OVERCAST = "overcast"
    PARTLY_CLOUDY = "partly_cloudy"

class WeatherData(BaseModel):
    temperature: float = Field(..., description="Temperature in Celsius")
    humidity: float = Field(..., description="Humidity percentage")
    wind_speed: float = Field(..., description="Wind speed in km/h")
    precipitation: float = Field(..., description="Precipitation in mm")
    condition: WeatherCondition = Field(..., description="Weather condition")
    visibility: float = Field(..., description="Visibility in km")
    pressure: float = Field(..., description="Atmospheric pressure in hPa")
    timestamp: datetime = Field(..., description="Weather data timestamp")

class AnimalPrediction(BaseModel):
    animal_type: str = Field(..., description="Type of animal")
    probability: float = Field(..., ge=0.0, le=1.0, description="Sighting probability (0-1)")
    optimal_time: TimeOfDay = Field(..., description="Best time to see this animal")
    best_location: str = Field(..., description="Best location in the park")
    confidence: float = Field(..., ge=0.0, le=1.0, description="Prediction confidence (0-1)")
    tips: str = Field(..., description="Tips for viewing this animal")
    weather_factor: float = Field(..., description="Weather impact on probability")
    seasonal_factor: float = Field(..., description="Seasonal impact on probability")
    time_factor: float = Field(..., description="Time of day impact on probability")
    recent_sightings: int = Field(..., description="Number of recent sightings")
    last_seen: Optional[datetime] = Field(None, description="Last reported sighting")

class PredictionRequest(BaseModel):
    park_id: str = Field(..., description="National park identifier")
    time_of_day: TimeOfDay = Field(..., description="Time of day for prediction")
    season: Season = Field(..., description="Current season")
    user_preferences: Optional[Dict[str, Any]] = Field(default_factory=dict, description="User preferences")
    include_weather: bool = Field(default=True, description="Include weather data in response")

class PredictionResponse(BaseModel):
    park_id: str = Field(..., description="National park identifier")
    predictions: Dict[str, AnimalPrediction] = Field(..., description="Animal predictions")
    weather_data: WeatherData = Field(..., description="Current weather data")
    timestamp: datetime = Field(..., description="Prediction timestamp")
    confidence_score: float = Field(..., ge=0.0, le=1.0, description="Overall prediction confidence")
    metadata: Optional[Dict[str, Any]] = Field(default_factory=dict, description="Additional metadata")

class RealTimeUpdate(BaseModel):
    park_id: str = Field(..., description="National park identifier")
    animal_type: str = Field(..., description="Type of animal")
    sighting_location: str = Field(..., description="Location of sighting")
    sighting_time: datetime = Field(..., description="Time of sighting")
    confidence: float = Field(..., ge=0.0, le=1.0, description="Sighting confidence")
    reported_by: str = Field(..., description="Who reported the sighting")
    additional_notes: Optional[str] = Field(None, description="Additional notes about the sighting")

class MLModelMetrics(BaseModel):
    model_name: str = Field(..., description="Name of the ML model")
    accuracy: float = Field(..., ge=0.0, le=1.0, description="Model accuracy")
    precision: float = Field(..., ge=0.0, le=1.0, description="Model precision")
    recall: float = Field(..., ge=0.0, le=1.0, description="Model recall")
    f1_score: float = Field(..., ge=0.0, le=1.0, description="Model F1 score")
    last_trained: datetime = Field(..., description="When the model was last trained")
    training_data_size: int = Field(..., description="Size of training dataset")
    prediction_count: int = Field(..., description="Total predictions made")
