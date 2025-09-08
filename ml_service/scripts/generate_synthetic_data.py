#!/usr/bin/env python3
"""
Synthetic Data Generator for AI Safari ML Prediction Engine

This script generates synthetic datasets for development and testing purposes.
In production, this would be replaced with real wildlife sighting data,
weather data, and animal behavior patterns.
"""

import os
import sys
import json
import numpy as np
import pandas as pd
from datetime import datetime, timedelta
from pathlib import Path

# Add the parent directory to the path to import models
sys.path.append(str(Path(__file__).parent.parent))

from models.prediction_models import TimeOfDay, Season, WeatherCondition

class SyntheticDataGenerator:
    def __init__(self):
        self.output_dir = Path("data/synthetic")
        self.parks = ["serengeti", "manyara", "mikumi", "gombe"]
        self.animal_types = [
            "lions", "elephants", "cheetahs", "wildebeest", "zebras",
            "giraffes", "buffalos", "leopards", "hyenas", "antelopes"
        ]
        
        # Create output directories
        self.output_dir.mkdir(parents=True, exist_ok=True)
        (self.output_dir / "sightings").mkdir(exist_ok=True)
        (self.output_dir / "weather").mkdir(exist_ok=True)
        (self.output_dir / "models").mkdir(exist_ok=True)
        (self.output_dir / "behavior").mkdir(exist_ok=True)
        
    def generate_wildlife_sightings(self, num_samples: int = 1000):
        """Generate synthetic wildlife sighting data"""
        print("🦁 Generating wildlife sighting data...")
        
        sightings = []
        np.random.seed(42)  # For reproducibility
        
        for _ in range(num_samples):
            # Random park and animal
            park_id = np.random.choice(self.parks)
            animal_type = np.random.choice(self.animal_types)
            
            # Random timestamp (last 2 years)
            days_ago = np.random.randint(0, 730)
            timestamp = datetime.now() - timedelta(days=days_ago)
            
            # Random location within park bounds
            if park_id == "serengeti":
                lat = np.random.uniform(-2.5, -1.5)
                lng = np.random.uniform(34.5, 35.5)
            elif park_id == "manyara":
                lat = np.random.uniform(-3.5, -3.0)
                lng = np.random.uniform(35.5, 36.0)
            elif park_id == "mikumi":
                lat = np.random.uniform(-7.0, -6.5)
                lng = np.random.uniform(37.0, 37.5)
            else:  # gombe
                lat = np.random.uniform(-4.5, -4.0)
                lng = np.random.uniform(29.5, 30.0)
            
            # Random weather conditions
            weather_conditions = {
                "temperature": np.random.uniform(15, 35),
                "humidity": np.random.uniform(40, 80),
                "wind_speed": np.random.uniform(0, 20),
                "precipitation": np.random.uniform(0, 50),
                "condition": np.random.choice(list(WeatherCondition)).value,
                "visibility": np.random.uniform(1, 20),
                "pressure": np.random.uniform(1000, 1030)
            }
            
            # Random time and season
            time_of_day = np.random.choice(list(TimeOfDay)).value
            season = np.random.choice(list(Season)).value
            
            # Sighting confidence based on conditions
            base_confidence = 0.7
            weather_factor = 1.0 if weather_conditions["visibility"] > 10 else 0.8
            time_factor = 1.2 if time_of_day in ["early_morning", "evening"] else 1.0
            season_factor = 1.1 if season == "dry" else 1.0
            
            confidence = min(base_confidence * weather_factor * time_factor * season_factor, 1.0)
            
            # Group size (some animals are social)
            if animal_type in ["wildebeest", "zebras", "buffalos"]:
                group_size = np.random.randint(5, 50)
            elif animal_type in ["lions", "elephants"]:
                group_size = np.random.randint(1, 15)
            else:
                group_size = np.random.randint(1, 8)
            
            sighting = {
                "id": f"sighting_{len(sightings):06d}",
                "park_id": park_id,
                "animal_type": animal_type,
                "timestamp": timestamp.isoformat(),
                "location_lat": round(lat, 6),
                "location_lng": round(lng, 6),
                "weather_conditions": weather_conditions,
                "time_of_day": time_of_day,
                "season": season,
                "sighting_confidence": round(confidence, 3),
                "reporter_type": np.random.choice(["ranger", "tourist", "researcher"]),
                "group_size": group_size,
                "notes": self._generate_sighting_notes(animal_type, weather_conditions)
            }
            
            sightings.append(sighting)
        
        # Save to file
        output_file = self.output_dir / "sightings" / "wildlife_sightings.json"
        with open(output_file, 'w') as f:
            json.dump(sightings, f, indent=2)
        
        print(f"✅ Generated {len(sightings)} wildlife sightings")
        print(f"📁 Saved to: {output_file}")
        
        return sightings
    
    def generate_weather_data(self, days: int = 730):
        """Generate synthetic historical weather data"""
        print("🌤️ Generating weather data...")
        
        weather_records = []
        np.random.seed(42)
        
        start_date = datetime.now() - timedelta(days=days)
        
        for day in range(days):
            current_date = start_date + timedelta(days=day)
            
            for hour in range(24):
                timestamp = current_date + timedelta(hours=hour)
                
                # Seasonal variations
                day_of_year = current_date.timetuple().tm_yday
                
                # Temperature varies by season
                if 60 <= day_of_year <= 150:  # Wet season (Mar-May)
                    base_temp = 25
                    temp_variation = 8
                elif 240 <= day_of_year <= 330:  # Dry season (Sep-Nov)
                    base_temp = 28
                    temp_variation = 10
                else:  # Transition seasons
                    base_temp = 26
                    temp_variation = 6
                
                # Daily temperature cycle
                hour_factor = np.cos((hour - 6) * np.pi / 12)  # Peak at 2 PM
                temperature = base_temp + hour_factor * temp_variation + np.random.normal(0, 2)
                
                # Humidity inversely related to temperature
                humidity = max(30, min(90, 80 - (temperature - 20) * 2 + np.random.normal(0, 10)))
                
                # Wind speed (higher during day)
                wind_speed = max(0, min(25, 5 + hour_factor * 8 + np.random.exponential(2)))
                
                # Precipitation (more likely during wet season)
                if 60 <= day_of_year <= 150:
                    precip_chance = 0.4
                else:
                    precip_chance = 0.1
                
                if np.random.random() < precip_chance:
                    precipitation = np.random.exponential(5)
                else:
                    precipitation = 0
                
                # Weather condition based on precipitation and humidity
                if precipitation > 10:
                    condition = "rainy"
                elif humidity > 80:
                    condition = "overcast"
                elif humidity > 60:
                    condition = "cloudy"
                elif hour < 6 or hour > 18:
                    condition = "clear"
                else:
                    condition = "sunny"
                
                weather_record = {
                    "timestamp": timestamp.isoformat(),
                    "park_id": np.random.choice(self.parks),
                    "temperature": round(temperature, 1),
                    "humidity": round(humidity, 1),
                    "wind_speed": round(wind_speed, 1),
                    "precipitation": round(precipitation, 1),
                    "condition": condition,
                    "visibility": max(1, min(20, 15 - precipitation/5 + np.random.normal(0, 2))),
                    "pressure": round(1013 + np.random.normal(0, 5), 1)
                }
                
                weather_records.append(weather_record)
        
        # Save to file
        output_file = self.output_dir / "weather" / "historical_weather.json"
        with open(output_file, 'w') as f:
            json.dump(weather_records, f, indent=2)
        
        print(f"✅ Generated {len(weather_records)} weather records")
        print(f"📁 Saved to: {output_file}")
        
        return weather_records
    
    def generate_animal_behavior(self):
        """Generate synthetic animal behavior patterns"""
        print("🐘 Generating animal behavior data...")
        
        behavior_patterns = {}
        
        for animal_type in self.animal_types:
            # Activity patterns
            if animal_type in ["lions", "cheetahs", "leopards"]:
                activity_pattern = "nocturnal_crepuscular"
                preferred_habitat = "open_plains"
                social_behavior = "pride_solitary"
            elif animal_type in ["elephants", "buffalos"]:
                activity_pattern = "diurnal"
                preferred_habitat = "woodland_water"
                social_behavior = "herd"
            elif animal_type in ["wildebeest", "zebras", "antelopes"]:
                activity_pattern = "diurnal"
                preferred_habitat = "grasslands"
                social_behavior = "herd"
            elif animal_type == "giraffes":
                activity_pattern = "diurnal"
                preferred_habitat = "acacia_woodland"
                social_behavior = "loose_groups"
            else:
                activity_pattern = "nocturnal"
                preferred_habitat = "mixed"
                social_behavior = "solitary"
            
            # Feeding times
            if animal_type in ["lions", "cheetahs", "leopards"]:
                feeding_times = ["early_morning", "evening", "night"]
            elif animal_type in ["elephants", "buffalos"]:
                feeding_times = ["morning", "afternoon", "evening"]
            else:
                feeding_times = ["early_morning", "morning", "late_afternoon"]
            
            # Migration patterns
            if animal_type in ["wildebeest", "zebras"]:
                migration_seasons = ["wet_to_dry", "dry_to_wet"]
                migration_distance = "long_distance"
            else:
                migration_seasons = []
                migration_distance = "local"
            
            # Weather preferences
            weather_preferences = {
                "temperature_range": {
                    "min": 15,
                    "max": 35,
                    "optimal": 25
                },
                "humidity_range": {
                    "min": 30,
                    "max": 80,
                    "optimal": 60
                },
                "precipitation_tolerance": "moderate" if animal_type in ["elephants", "buffalos"] else "low"
            }
            
            behavior_patterns[animal_type] = {
                "activity_pattern": activity_pattern,
                "preferred_habitat": preferred_habitat,
                "social_behavior": social_behavior,
                "feeding_times": feeding_times,
                "migration_seasons": migration_seasons,
                "migration_distance": migration_distance,
                "weather_preferences": weather_preferences,
                "conservation_status": "least_concern",
                "population_trend": "stable",
                "threats": ["habitat_loss", "human_conflict"] if animal_type in ["lions", "elephants"] else ["habitat_loss"]
            }
        
        # Save to file
        output_file = self.output_dir / "behavior" / "animal_behavior.json"
        with open(output_file, 'w') as f:
            json.dump(behavior_patterns, f, indent=2)
        
        print(f"✅ Generated behavior patterns for {len(behavior_patterns)} animal types")
        print(f"📁 Saved to: {output_file}")
        
        return behavior_patterns
    
    def generate_park_environmental_data(self):
        """Generate synthetic park environmental data"""
        print("🌿 Generating park environmental data...")
        
        park_data = {}
        
        for park_id in self.parks:
            if park_id == "serengeti":
                park_data[park_id] = {
                    "vegetation_type": "grassland_savanna",
                    "water_availability": "seasonal_rivers",
                    "terrain_type": "rolling_plains",
                    "human_activity_level": "low",
                    "conservation_status": "strict_protection",
                    "area_km2": 14750,
                    "elevation_range": {"min": 920, "max": 1850},
                    "annual_rainfall_mm": 1000,
                    "dominant_ecosystem": "serengeti_ecosystem"
                }
            elif park_id == "manyara":
                park_data[park_id] = {
                    "vegetation_type": "forest_grassland",
                    "water_availability": "permanent_lake",
                    "terrain_type": "escarpment_lake",
                    "human_activity_level": "moderate",
                    "conservation_status": "national_park",
                    "area_km2": 325,
                    "elevation_range": {"min": 960, "max": 1800},
                    "annual_rainfall_mm": 800,
                    "dominant_ecosystem": "lake_manyara_ecosystem"
                }
            elif park_id == "mikumi":
                park_data[park_id] = {
                    "vegetation_type": "grassland_woodland",
                    "water_availability": "seasonal_waterholes",
                    "terrain_type": "open_plains",
                    "human_activity_level": "moderate",
                    "conservation_status": "national_park",
                    "area_km2": 3230,
                    "elevation_range": {"min": 550, "max": 1200},
                    "annual_rainfall_mm": 900,
                    "dominant_ecosystem": "mikumi_ecosystem"
                }
            else:  # gombe
                park_data[park_id] = {
                    "vegetation_type": "tropical_forest",
                    "water_availability": "streams_springs",
                    "terrain_type": "mountainous_forest",
                    "human_activity_level": "low",
                    "conservation_status": "national_park",
                    "area_km2": 52,
                    "elevation_range": {"min": 800, "max": 1500},
                    "annual_rainfall_mm": 1500,
                    "dominant_ecosystem": "gombe_ecosystem"
                }
        
        # Save to file
        output_file = self.output_dir / "park_environmental.json"
        with open(output_file, 'w') as f:
            json.dump(park_data, f, indent=2)
        
        print(f"✅ Generated environmental data for {len(park_data)} parks")
        print(f"📁 Saved to: {output_file}")
        
        return park_data
    
    def _generate_sighting_notes(self, animal_type: str, weather_conditions: dict) -> str:
        """Generate realistic sighting notes"""
        notes_templates = {
            "lions": [
                "Pride of {count} lions resting under acacia tree",
                "Lioness hunting near water source",
                "Male lion patrolling territory",
                "Lion cubs playing in grass"
            ],
            "elephants": [
                "Herd of {count} elephants at waterhole",
                "Elephant calf following mother",
                "Bull elephant in musth",
                "Elephants browsing on acacia"
            ],
            "cheetahs": [
                "Cheetah on termite mound scanning for prey",
                "Cheetah family with cubs",
                "Cheetah stalking impala",
                "Cheetah resting in shade"
            ]
        }
        
        template = notes_templates.get(animal_type, ["{animal_type} observed in natural habitat"])
        note = np.random.choice(template)
        
        # Replace placeholders
        note = note.replace("{animal_type}", animal_type.title())
        note = note.replace("{count}", str(np.random.randint(1, 10)))
        
        # Add weather context
        if weather_conditions["precipitation"] > 10:
            note += " during light rain"
        elif weather_conditions["temperature"] > 30:
            note += " in hot weather"
        elif weather_conditions["visibility"] < 10:
            note += " in reduced visibility"
        
        return note
    
    def generate_all_data(self):
        """Generate all synthetic datasets"""
        print("🚀 Starting synthetic data generation...")
        print("=" * 50)
        
        try:
            # Generate wildlife sightings
            sightings = self.generate_wildlife_sightings(1000)
            
            # Generate weather data
            weather = self.generate_weather_data(730)  # 2 years
            
            # Generate animal behavior
            behavior = self.generate_animal_behavior()
            
            # Generate park environmental data
            parks = self.generate_park_environmental_data()
            
            # Create summary
            summary = {
                "generation_timestamp": datetime.now().isoformat(),
                "datasets_generated": {
                    "wildlife_sightings": len(sightings),
                    "weather_records": len(weather),
                    "animal_types": len(behavior),
                    "parks": len(parks)
                },
                "data_quality": "synthetic_for_development",
                "notes": "This data is generated for development and testing purposes. Replace with real data in production."
            }
            
            # Save summary
            summary_file = self.output_dir / "generation_summary.json"
            with open(summary_file, 'w') as f:
                json.dump(summary, f, indent=2)
            
            print("\n" + "=" * 50)
            print("🎉 Synthetic data generation completed!")
            print("=" * 50)
            print(f"📊 Total datasets: {summary['datasets_generated']}")
            print(f"📁 Output directory: {self.output_dir}")
            print(f"📋 Summary: {summary_file}")
            print("\n⚠️  Note: This is synthetic data for development.")
            print("   Replace with real datasets in production for accurate predictions.")
            
        except Exception as e:
            print(f"❌ Error generating data: {e}")
            raise

def main():
    """Main function to run the data generator"""
    try:
        generator = SyntheticDataGenerator()
        generator.generate_all_data()
        
    except KeyboardInterrupt:
        print("\n⏹️  Data generation interrupted by user")
    except Exception as e:
        print(f"\n💥 Data generation failed: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()
