import sys
import os
from loguru import logger
from datetime import datetime

def setup_logger():
    """Setup and configure the logger for the ML service"""
    
    # Remove default logger
    logger.remove()
    
    # Create logs directory if it doesn't exist
    os.makedirs("logs", exist_ok=True)
    
    # Console logger with colors and emojis
    logger.add(
        sys.stdout,
        format="<green>{time:YYYY-MM-DD HH:mm:ss}</green> | <level>{level: <8}</level> | <cyan>{name}</cyan>:<cyan>{function}</cyan>:<cyan>{line}</cyan> - <level>{message}</level>",
        level="INFO",
        colorize=True
    )
    
    # File logger for all levels
    logger.add(
        "logs/ml_service.log",
        format="{time:YYYY-MM-DD HH:mm:ss} | {level: <8} | {name}:{function}:{line} - {message}",
        level="DEBUG",
        rotation="10 MB",
        retention="7 days",
        compression="zip"
    )
    
    # Error file logger
    logger.add(
        "logs/ml_service_errors.log",
        format="{time:YYYY-MM-DD HH:mm:ss} | {level: <8} | {name}:{function}:{line} - {message}",
        level="ERROR",
        rotation="5 MB",
        retention="30 days",
        compression="zip"
    )
    
    # Performance logger
    logger.add(
        "logs/ml_service_performance.log",
        format="{time:YYYY-MM-DD HH:mm:ss} | {level: <8} | {name}:{function}:{line} - {message}",
        level="INFO",
        filter=lambda record: "performance" in record["message"].lower() or "timing" in record["message"].lower(),
        rotation="10 MB",
        retention="7 days",
        compression="zip"
    )
    
    return logger

def log_performance(func_name: str, start_time: datetime, end_time: datetime = None, **kwargs):
    """Log performance metrics for a function"""
    if end_time is None:
        end_time = datetime.now()
    
    duration = (end_time - start_time).total_seconds()
    
    # Log performance data
    logger.info(
        f"Performance | {func_name} | Duration: {duration:.3f}s | {kwargs}",
        extra={"performance": True}
    )
    
    return duration

def log_api_request(method: str, endpoint: str, duration: float, status_code: int, **kwargs):
    """Log API request metrics"""
    logger.info(
        f"API Request | {method} {endpoint} | Status: {status_code} | Duration: {duration:.3f}s | {kwargs}",
        extra={"api_request": True}
    )

def log_ml_prediction(park_id: str, animal_type: str, confidence: float, duration: float, **kwargs):
    """Log ML prediction metrics"""
    logger.info(
        f"ML Prediction | Park: {park_id} | Animal: {animal_type} | Confidence: {confidence:.3f} | Duration: {duration:.3f}s | {kwargs}",
        extra={"ml_prediction": True}
    )

def log_weather_update(park_id: str, temperature: float, condition: str, duration: float, **kwargs):
    """Log weather update metrics"""
    logger.info(
        f"Weather Update | Park: {park_id} | Temp: {temperature}°C | Condition: {condition} | Duration: {duration:.3f}s | {kwargs}",
        extra={"weather_update": True}
    )

def log_data_sync(service: str, records_count: int, duration: float, **kwargs):
    """Log data synchronization metrics"""
    logger.info(
        f"Data Sync | Service: {service} | Records: {records_count} | Duration: {duration:.3f}s | {kwargs}",
        extra={"data_sync": True}
    )

def log_error_with_context(error: Exception, context: str, **kwargs):
    """Log error with additional context"""
    logger.error(
        f"Error in {context} | {type(error).__name__}: {str(error)} | {kwargs}",
        extra={"error_context": context}
    )

def log_system_health(component: str, status: str, **kwargs):
    """Log system health status"""
    logger.info(
        f"System Health | Component: {component} | Status: {status} | {kwargs}",
        extra={"system_health": True}
    )

def log_user_activity(user_id: str, action: str, **kwargs):
    """Log user activity"""
    logger.info(
        f"User Activity | User: {user_id} | Action: {action} | {kwargs}",
        extra={"user_activity": True}
    )

def log_cache_operation(operation: str, key: str, success: bool, duration: float = None, **kwargs):
    """Log cache operations"""
    status = "✅ Success" if success else "❌ Failed"
    duration_str = f" | Duration: {duration:.3f}s" if duration else ""
    
    logger.info(
        f"Cache {operation} | Key: {key} | {status}{duration_str} | {kwargs}",
        extra={"cache_operation": True}
    )

def log_database_operation(operation: str, table: str, records_affected: int = None, duration: float = None, **kwargs):
    """Log database operations"""
    records_str = f" | Records: {records_affected}" if records_affected is not None else ""
    duration_str = f" | Duration: {duration:.3f}s" if duration else ""
    
    logger.info(
        f"Database {operation} | Table: {table}{records_str}{duration_str} | {kwargs}",
        extra={"database_operation": True}
    )

def log_redis_operation(operation: str, key: str, success: bool, duration: float = None, **kwargs):
    """Log Redis operations"""
    status = "✅ Success" if success else "❌ Failed"
    duration_str = f" | Duration: {duration:.3f}s" if duration else ""
    
    logger.info(
        f"Redis {operation} | Key: {key} | {status}{duration_str} | {kwargs}",
        extra={"redis_operation": True}
    )

def log_model_metrics(model_name: str, accuracy: float, precision: float, recall: float, f1_score: float, **kwargs):
    """Log ML model performance metrics"""
    logger.info(
        f"Model Metrics | {model_name} | Accuracy: {accuracy:.3f} | Precision: {precision:.3f} | Recall: {recall:.3f} | F1: {f1_score:.3f} | {kwargs}",
        extra={"model_metrics": True}
    )

def log_background_task(task_name: str, status: str, duration: float = None, **kwargs):
    """Log background task execution"""
    duration_str = f" | Duration: {duration:.3f}s" if duration else ""
    
    logger.info(
        f"Background Task | {task_name} | Status: {status}{duration_str} | {kwargs}",
        extra={"background_task": True}
    )

def log_startup_component(component: str, status: str, duration: float = None, **kwargs):
    """Log component startup status"""
    duration_str = f" | Duration: {duration:.3f}s" if duration else ""
    
    logger.info(
        f"Startup | Component: {component} | Status: {status}{duration_str} | {kwargs}",
        extra={"startup": True}
    )

def log_shutdown_component(component: str, status: str, duration: float = None, **kwargs):
    """Log component shutdown status"""
    duration_str = f" | Duration: {duration:.3f}s" if duration else ""
    
    logger.info(
        f"Shutdown | Component: {component} | Status: {status}{duration_str} | {kwargs}",
        extra={"shutdown": True}
    )

# Performance decorator
def log_performance_decorator(func):
    """Decorator to automatically log performance metrics"""
    import functools
    
    @functools.wraps(func)
    async def async_wrapper(*args, **kwargs):
        start_time = datetime.now()
        try:
            result = await func(*args, **kwargs)
            duration = log_performance(func.__name__, start_time, **kwargs)
            return result
        except Exception as e:
            duration = log_performance(func.__name__, start_time, **kwargs)
            log_error_with_context(e, func.__name__, duration=duration)
            raise
    
    @functools.wraps(func)
    def sync_wrapper(*args, **kwargs):
        start_time = datetime.now()
        try:
            result = func(*args, **kwargs)
            duration = log_performance(func.__name__, start_time, **kwargs)
            return result
        except Exception as e:
            duration = log_performance(func.__name__, start_time, **kwargs)
            log_error_with_context(e, func.__name__, duration=duration)
            raise
    
    if asyncio.iscoroutinefunction(func):
        return async_wrapper
    else:
        return sync_wrapper
