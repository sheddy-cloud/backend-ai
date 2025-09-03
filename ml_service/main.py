from fastapi import FastAPI, HTTPException, BackgroundTasks
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
import uvicorn
import asyncio
import schedule
import time
from datetime import datetime, timedelta
import os
from dotenv import load_dotenv

from services.weather_service import WeatherService
from services.prediction_service import PredictionService
from services.data_sync_service import DataSyncService
from services.real_time_service import RealTimeService
from models.prediction_models import PredictionRequest, PredictionResponse
from utils.logger import setup_logger

# Load environment variables
load_dotenv()

# Setup logging
logger = setup_logger()

# Initialize FastAPI app
app = FastAPI(
    title="AI Safari ML Prediction Engine",
    description="Real-time wildlife predictions powered by machine learning",
    version="2.0.0"
)

# CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Initialize services
weather_service = WeatherService()
prediction_service = PredictionService()
data_sync_service = DataSyncService()
real_time_service = RealTimeService()

@app.on_event("startup")
async def startup_event():
    """Initialize services on startup"""
    logger.info("🚀 Starting AI Safari ML Prediction Engine...")
    
    # Initialize all services
    await weather_service.initialize()
    await prediction_service.initialize()
    await data_sync_service.initialize()
    await real_time_service.initialize()
    
    # Start background tasks
    asyncio.create_task(start_background_tasks())
    
    logger.info("✅ ML Prediction Engine started successfully!")

@app.get("/health")
async def health_check():
    """Health check endpoint"""
    return {
        "status": "healthy",
        "service": "AI Safari ML Prediction Engine",
        "timestamp": datetime.now().isoformat(),
        "version": "2.0.0"
    }

@app.post("/predict/wildlife", response_model=PredictionResponse)
async def predict_wildlife(request: PredictionRequest):
    """Get real-time wildlife predictions with ML"""
    try:
        logger.info(f"🦁 Processing wildlife prediction request for {request.park_id}")
        
        # Get current weather data
        weather_data = await weather_service.get_current_weather(request.park_id)
        
        # Get ML predictions
        predictions = await prediction_service.predict_wildlife_sightings(
            park_id=request.park_id,
            weather_data=weather_data,
            time_of_day=request.time_of_day,
            season=request.season
        )
        
        # Update real-time data
        await real_time_service.update_predictions(request.park_id, predictions)
        
        return PredictionResponse(
            park_id=request.park_id,
            predictions=predictions,
            weather_data=weather_data,
            timestamp=datetime.now().isoformat(),
            confidence_score=prediction_service.get_confidence_score(predictions)
        )
        
    except Exception as e:
        logger.error(f"❌ Error in wildlife prediction: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/predictions/{park_id}/realtime")
async def get_realtime_predictions(park_id: str):
    """Get real-time predictions for a specific park"""
    try:
        predictions = await real_time_service.get_current_predictions(park_id)
        return {
            "park_id": park_id,
            "predictions": predictions,
            "last_updated": datetime.now().isoformat()
        }
    except Exception as e:
        logger.error(f"❌ Error getting real-time predictions: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/sync/weather")
async def sync_weather_data(background_tasks: BackgroundTasks):
    """Sync weather data for all parks"""
    try:
        background_tasks.add_task(weather_service.sync_all_parks_weather)
        return {"message": "Weather sync started in background", "timestamp": datetime.now().isoformat()}
    except Exception as e:
        logger.error(f"❌ Error starting weather sync: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/sync/predictions")
async def sync_predictions(background_tasks: BackgroundTasks):
    """Sync ML predictions for all parks"""
    try:
        background_tasks.add_task(prediction_service.sync_all_predictions)
        return {"message": "Predictions sync started in background", "timestamp": datetime.now().isoformat()}
    except Exception as e:
        logger.error(f"❌ Error starting predictions sync: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))

async def start_background_tasks():
    """Start background tasks for real-time updates"""
    logger.info("🔄 Starting background tasks...")
    
    # Schedule weather updates every 30 minutes
    schedule.every(30).minutes.do(lambda: asyncio.create_task(weather_service.sync_all_parks_weather))
    
    # Schedule prediction updates every hour
    schedule.every().hour.do(lambda: asyncio.create_task(prediction_service.sync_all_predictions))
    
    # Schedule data sync every 2 hours
    schedule.every(2).hours.do(lambda: asyncio.create_task(data_sync_service.sync_all_data))
    
    while True:
        schedule.run_pending()
        await asyncio.sleep(60)  # Check every minute

if __name__ == "__main__":
    port = int(os.getenv("ML_SERVICE_PORT", 8000))
    uvicorn.run(
        "main:app",
        host="0.0.0.0",
        port=port,
        reload=True,
        log_level="info"
    )
