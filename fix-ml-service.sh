#!/bin/bash

echo "🔧 Fixing ML Service - FastAPI Missing"
echo "======================================"

# Navigate to application directory
cd /opt/napasa-ai-backend

echo "1. Stopping ML service..."
pm2 stop napasa-ml-service
pm2 delete napasa-ml-service

echo "2. Setting up Python virtual environment..."
cd ml_service

# Remove existing venv if it exists
if [ -d "venv" ]; then
    echo "   Removing existing virtual environment..."
    rm -rf venv
fi

# Create new virtual environment
echo "   Creating new Python virtual environment..."
python3 -m venv venv

# Activate virtual environment
echo "   Activating virtual environment..."
source venv/bin/activate

# Upgrade pip
echo "   Upgrading pip..."
pip install --upgrade pip

# Install required packages
echo "   Installing FastAPI and dependencies..."
pip install fastapi
pip install uvicorn[standard]
pip install python-multipart
pip install python-jose[cryptography]
pip install passlib[bcrypt]
pip install python-dotenv
pip install psycopg2-binary
pip install redis
pip install requests
pip install numpy
pip install pandas
pip install scikit-learn

# If requirements.txt exists, install from it too
if [ -f "requirements.txt" ]; then
    echo "   Installing from requirements.txt..."
    pip install -r requirements.txt
fi

# Deactivate virtual environment
deactivate

echo "3. Creating environment file..."
cat > .env << 'EOF'
PORT=8000
HOST=0.0.0.0
ENVIRONMENT=production
DB_HOST=localhost
DB_PORT=5432
DB_NAME=ai_safari_db
DB_USER=napasa_user
DB_PASSWORD=napasa_password
REDIS_HOST=localhost
REDIS_PORT=6379
LOG_LEVEL=INFO
EOF

# Create logs directory
mkdir -p logs

cd ..

echo "4. Testing Python environment..."
cd ml_service
source venv/bin/activate
echo "   Testing FastAPI import..."
python -c "import fastapi; print('✅ FastAPI imported successfully')"
echo "   Testing uvicorn import..."
python -c "import uvicorn; print('✅ Uvicorn imported successfully')"
deactivate
cd ..

echo "5. Starting ML service with PM2..."
pm2 start ecosystem.config.js --only napasa-ml-service

echo "6. Waiting for service to start..."
sleep 5

echo "7. Checking service status..."
pm2 status

echo "8. Testing ML service..."
sleep 3
if curl -s --connect-timeout 5 http://localhost:8000/health; then
    echo "   ✅ ML Service is now responding!"
else
    echo "   ❌ ML Service still not responding"
    echo "   Checking logs..."
    pm2 logs napasa-ml-service --lines 10 --nostream
fi

echo ""
echo "🎉 ML Service fix completed!"
echo ""
echo "📋 Test your endpoints:"
echo "curl http://13.51.162.253:8000/health  # Direct to ML Service"
echo "curl http://13.51.162.253/ml/health    # Via Nginx to ML Service"
echo ""
echo "📋 Useful commands:"
echo "pm2 status                    # Check app status"
echo "pm2 logs napasa-ml-service    # View ML service logs"
echo "pm2 restart napasa-ml-service # Restart ML service"



