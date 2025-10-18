# 🚀 AI Safari ML Service - Quick Start Guide

## 🎯 What We've Built

The **AI Safari ML Prediction Engine** is a complete Python-based machine learning service that provides real-time wildlife sighting predictions for Tanzania's national parks. It combines:

- **ML Prediction Service**: Random Forest models for each park
- **Weather Integration**: Real-time weather data from OpenWeatherMap API
- **Real-time Updates**: Redis-based caching and real-time notifications
- **Data Synchronization**: Bidirectional sync between PostgreSQL and Redis
- **Comprehensive Logging**: Structured logging with Loguru

## 🏗️ Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   FastAPI App   │    │  ML Prediction  │    │  Weather API    │
│   (Port 8000)   │◄──►│     Service     │◄──►│  Integration    │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         ▼                       ▼                       ▼
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Redis Cache   │    │  Real-time      │    │  Data Sync      │
│   & Pub/Sub     │    │   Service       │    │   Service       │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         ▼                       ▼                       ▼
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│  PostgreSQL     │    │  Background     │    │  Scheduled      │
│   Database      │    │   Tasks         │    │   Jobs          │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

## 🚀 Quick Start

### 1. **Generate Synthetic Data**
```bash
cd ml_service
python run_data_generator.py
```

This creates:
- `data/synthetic/sightings/wildlife_sightings.json` (1000 samples)
- `data/synthetic/weather/historical_weather.json` (2 years)
- `data/synthetic/behavior/animal_behavior.json` (10 species)
- `data/synthetic/park_environmental.json` (4 parks)

### 2. **Start the ML Service**
```bash
# Local development
python main.py

# Or with Docker
docker-compose -f docker-compose.ml.yml up ml_service
```

### 3. **Test the Service**
```bash
python test_service.py
```

## 📊 API Endpoints

### **Health & Status**
- `GET /health` - Service health check
- `GET /status` - System status and metrics

### **Wildlife Predictions**
- `POST /predict/wildlife` - Get ML predictions for a park
- `GET /predictions/{park_id}/realtime` - Real-time predictions
- `GET /predictions/{park_id}/history` - Prediction history

### **Weather & Sync**
- `POST /sync/weather` - Sync weather data for all parks
- `POST /sync/predictions` - Sync ML predictions
- `GET /weather/{park_id}` - Current weather for a park

## 🧠 ML Models

### **Current Models**
- **Serengeti**: Random Forest (100 estimators)
- **Manyara**: Random Forest (100 estimators)  
- **Mikumi**: Random Forest (100 estimators)
- **Gombe**: Random Forest (100 estimators)

### **Features Used**
1. Temperature (°C)
2. Humidity (%)
3. Wind Speed (km/h)
4. Precipitation (mm)
5. Weather Condition (enum)
6. Visibility (km)
7. Pressure (hPa)
8. Time of Day (enum)
9. Season (enum)

### **Model Performance**
- **Training Data**: 1000 synthetic samples per park
- **Validation**: 20% holdout set
- **Metrics**: R² score, MSE, Precision, Recall, F1
- **Update Frequency**: Configurable (default: 1 hour)

## 🌤️ Weather Integration

### **Data Sources**
- **Primary**: OpenWeatherMap API (real-time)
- **Fallback**: Synthetic weather patterns
- **Cache TTL**: 30 minutes
- **Update Frequency**: Every 2 hours

### **Weather Factors**
- Temperature impact on animal activity
- Precipitation effects on visibility
- Wind speed influence on behavior
- Seasonal weather patterns

## 📡 Real-time Features

### **Live Updates**
- Redis Pub/Sub for real-time notifications
- WebSocket-ready architecture
- Background task processing
- Scheduled data updates

### **Caching Strategy**
- **Predictions**: 1 hour TTL
- **Weather**: 30 minutes TTL
- **Real-time data**: 2 hours TTL
- **Sightings**: 24 hours TTL

## 🔄 Data Synchronization

### **Sync Operations**
- **ML → Database**: Wildlife predictions
- **Database → ML**: Park information, user preferences
- **Real-time → Database**: Recent sightings
- **Frequency**: Every 2 hours (configurable)

### **Data Flow**
```
ML Service → Redis Cache → Data Sync → PostgreSQL
     ↑                                           ↓
Weather API ← Real-time Service ← Background Tasks
```

## 📈 Monitoring & Logging

### **Log Files**
- `logs/ml_service.log` - All logs
- `logs/ml_service_errors.log` - Error logs only
- `logs/ml_service_performance.log` - Performance metrics

### **Metrics Tracked**
- API request performance
- ML prediction accuracy
- Weather update timing
- Data sync operations
- Cache hit rates
- Model training metrics

## 🐳 Docker Deployment

### **Full Stack**
```bash
docker-compose -f docker-compose.ml.yml up -d
```

### **Services**
- **PostgreSQL**: Database (port 5432)
- **Redis**: Cache & Pub/Sub (port 6379)
- **ML Service**: Python FastAPI (port 8000)
- **Backend**: Node.js (port 3000)
- **Nginx**: Reverse proxy (port 80)

## 🔧 Configuration

### **Environment Variables**
```bash
# ML Service
ML_SERVICE_PORT=8000
OPENWEATHER_API_KEY=your_key_here

# Database
DB_HOST=localhost
DB_NAME=ai_safari_db
DB_USER=postgres

# Redis
REDIS_HOST=localhost
REDIS_PORT=6379

# ML Models
MODEL_UPDATE_INTERVAL=3600
MODEL_TRAINING_ENABLED=true
```

## 🧪 Testing

### **Run All Tests**
```bash
python test_service.py
```

### **Test Coverage**
- ✅ Health check endpoint
- ✅ Wildlife prediction API
- ✅ Real-time predictions
- ✅ Weather synchronization
- ✅ Data sync operations

## 🚀 Production Deployment

### **Requirements**
- Python 3.11+
- PostgreSQL 15+
- Redis 7+
- 2GB+ RAM
- Stable internet connection

### **Security**
- CORS configuration
- Rate limiting
- Environment variable protection
- Non-root Docker containers

### **Scaling**
- Horizontal scaling with load balancer
- Redis cluster for high availability
- Database connection pooling
- Background task queues

## 🔮 Future Enhancements

### **Phase 3: Advanced ML**
- Deep Learning models (CNN, RNN)
- Computer vision for image analysis
- Natural language processing for reports
- Ensemble methods for better accuracy

### **Phase 4: Real-time Analytics**
- Live dashboards
- Predictive analytics
- Anomaly detection
- Trend analysis

### **Phase 5: Mobile Integration**
- Real-time notifications
- Offline prediction caching
- GPS-based recommendations
- Social features

## 🆘 Troubleshooting

### **Common Issues**
1. **Redis Connection Failed**: Check Redis service status
2. **ML Model Training Error**: Verify Python dependencies
3. **Weather API Error**: Check API key and internet connection
4. **Database Sync Failed**: Verify PostgreSQL credentials

### **Debug Mode**
```bash
export LOG_LEVEL=DEBUG
python main.py
```

### **Health Checks**
```bash
curl http://localhost:8000/health
curl http://localhost:8000/status
```

## 📚 Additional Resources

- **Full Documentation**: `README.md`
- **API Reference**: OpenAPI docs at `/docs`
- **Data Schema**: `models/prediction_models.py`
- **Configuration**: `.env` file
- **Docker Setup**: `docker-compose.ml.yml`

---

**🎯 Ready to deploy!** The ML service is fully functional with synthetic data and ready for production use with real datasets.
