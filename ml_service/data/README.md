# 📊 AI Safari ML Datasets

This directory contains the datasets needed to train and operate the ML prediction engine.

## 🎯 **Required Datasets**

### 1. **Wildlife Sighting Data** 🦁
- **Source**: Park rangers, tourists, research studies
- **Format**: CSV/JSON with timestamps, locations, animal types
- **Fields**: 
  - `timestamp`, `park_id`, `animal_type`, `location_lat`, `location_lng`
  - `weather_conditions`, `time_of_day`, `season`, `sighting_confidence`
  - `reporter_type` (ranger/tourist/researcher), `group_size`

### 2. **Weather Historical Data** 🌤️
- **Source**: OpenWeatherMap API, local weather stations
- **Format**: Time-series data with hourly/daily records
- **Fields**:
  - `timestamp`, `park_id`, `temperature`, `humidity`, `wind_speed`
  - `precipitation`, `pressure`, `visibility`, `weather_condition`

### 3. **Animal Behavior Patterns** 🐘
- **Source**: Wildlife research papers, conservation studies
- **Format**: Structured data about species-specific behaviors
- **Fields**:
  - `animal_type`, `activity_pattern`, `preferred_habitat`
  - `migration_seasons`, `feeding_times`, `social_behavior`

### 4. **Park Environmental Data** 🌿
- **Source**: Satellite imagery, ecological surveys
- **Format**: Geospatial and environmental metrics
- **Fields**:
  - `park_id`, `vegetation_type`, `water_availability`, `terrain_type`
  - `human_activity_level`, `conservation_status`

## 📁 **Directory Structure**

```
data/
├── raw/                    # Original, unprocessed data
│   ├── sightings/         # Wildlife sighting reports
│   ├── weather/           # Historical weather data
│   ├── research/          # Academic research data
│   └── satellite/         # Remote sensing data
├── processed/             # Cleaned and formatted data
│   ├── training/          # ML training datasets
│   ├── validation/        # Model validation data
│   └── testing/           # Model testing data
├── external/              # Third-party datasets
│   ├── openweather/       # OpenWeatherMap historical data
│   ├── conservation/      # Conservation organization data
│   └── academic/          # Research paper datasets
└── synthetic/             # Generated data for development
    ├── sightings/         # Simulated wildlife data
    ├── weather/           # Simulated weather patterns
    └── models/            # Pre-trained ML models
```

## 🚀 **Getting Started with Real Data**

### **Option 1: Public Datasets**
```bash
# Download sample datasets
wget https://example.com/wildlife-sightings.csv
wget https://example.com/weather-history.csv
wget https://example.com/animal-behavior.json
```

### **Option 2: Collect Your Own Data**
```bash
# Set up data collection scripts
python scripts/collect_sightings.py
python scripts/collect_weather.py
python scripts/collect_research.py
```

### **Option 3: Use Synthetic Data (Current)**
```bash
# Generate synthetic datasets for development
python scripts/generate_synthetic_data.py
```

## 📊 **Dataset Requirements**

### **Minimum Data Requirements**
- **Wildlife Sightings**: 10,000+ records per park
- **Weather Data**: 2+ years of hourly data
- **Animal Behavior**: 50+ species documented
- **Park Data**: All 4 national parks covered

### **Data Quality Standards**
- **Completeness**: >90% of required fields populated
- **Accuracy**: <5% error rate in critical fields
- **Timeliness**: Data updated within 24 hours
- **Consistency**: Standardized formats across sources

## 🔧 **Data Processing Pipeline**

### **1. Data Ingestion**
```python
# Collect data from various sources
from data.ingestion import DataCollector
collector = DataCollector()
collector.collect_sightings()
collector.collect_weather()
collector.collect_research()
```

### **2. Data Cleaning**
```python
# Clean and validate data
from data.cleaning import DataCleaner
cleaner = DataCleaner()
clean_data = cleaner.clean_all_datasets()
```

### **3. Feature Engineering**
```python
# Create ML features
from data.features import FeatureEngineer
engineer = FeatureEngineer()
features = engineer.create_features(clean_data)
```

### **4. Dataset Creation**
```python
# Split into training/validation/testing
from data.splitting import DatasetSplitter
splitter = DatasetSplitter()
train, val, test = splitter.split_datasets(features)
```

## 📈 **Current Synthetic Data**

Since we don't have real datasets yet, the system uses:

### **Synthetic Wildlife Data**
- **1000 samples per park** (4000 total)
- **9 environmental features** per sample
- **Realistic probability distributions** based on known patterns
- **Seasonal and temporal variations** included

### **Synthetic Weather Data**
- **Default weather patterns** for each park
- **Realistic temperature ranges** (15-35°C)
- **Seasonal humidity variations** (40-80%)
- **Wind speed patterns** (0-20 km/h)

### **Synthetic Animal Behavior**
- **Known behavioral patterns** from research
- **Weather impact factors** for each species
- **Time-of-day preferences** for different animals
- **Seasonal migration patterns**

## 🎯 **Next Steps to Get Real Data**

### **Immediate Actions (Week 1)**
1. **Contact national parks** for sighting data
2. **Set up OpenWeatherMap** historical data API
3. **Research academic datasets** for animal behavior
4. **Create data collection forms** for rangers

### **Short Term (Month 1)**
1. **Implement data collection** from multiple sources
2. **Set up automated data pipelines** for real-time updates
3. **Validate data quality** and consistency
4. **Train models** on real data

### **Medium Term (Month 3)**
1. **Continuous data collection** from park operations
2. **Integration with tourist apps** for crowd-sourced data
3. **Satellite data integration** for environmental monitoring
4. **Advanced ML models** trained on real data

## 🔍 **Data Sources to Explore**

### **Wildlife Data**
- **Tanzania Wildlife Research Institute** (TAWIRI)
- **Serengeti Research Project** (long-term studies)
- **Tourist sighting reports** (mobile apps)
- **Ranger daily reports** (official records)

### **Weather Data**
- **OpenWeatherMap** (historical API)
- **Tanzania Meteorological Agency**
- **Local weather stations** in parks
- **Satellite weather data** (NASA, ESA)

### **Research Data**
- **Scientific papers** on East African wildlife
- **Conservation organization** databases
- **University research** projects
- **Government wildlife** surveys

## 📊 **Data Validation & Quality**

### **Automated Checks**
```python
# Run data quality checks
python scripts/validate_data.py

# Check for missing values
python scripts/check_completeness.py

# Validate data ranges
python scripts/validate_ranges.py
```

### **Manual Review**
- **Expert review** of animal behavior data
- **Park ranger validation** of sighting reports
- **Weather data** cross-reference with local stations
- **Research data** peer review process

## 🎉 **Success Metrics**

### **Data Quality Targets**
- **Completeness**: >95% of required fields
- **Accuracy**: <2% error rate
- **Coverage**: All 4 parks, all major species
- **Timeliness**: <1 hour update delay

### **ML Model Performance**
- **Prediction Accuracy**: >90% on real data
- **Confidence Scores**: Reliable uncertainty estimates
- **Real-time Performance**: <100ms response time
- **Continuous Learning**: Improving with new data

---

**Note**: Currently using synthetic data for development. Real datasets will significantly improve prediction accuracy and provide genuine wildlife insights! 🚀
