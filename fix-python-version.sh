#!/bin/bash

echo "🔧 Fixing Python Version Compatibility (Using Python 3.11)"
echo "========================================================="

# Navigate to application directory
cd /opt/napasa-ai-backend

echo "1. Installing Python 3.11 and removing Python 3.12..."
sudo apt update
sudo apt install -y software-properties-common
sudo add-apt-repository -y ppa:deadsnakes/ppa
sudo apt update

# Install Python 3.11 and related packages
sudo apt install -y \
    python3.11 \
    python3.11-dev \
    python3.11-venv \
    python3.11-distutils \
    python3-pip \
    build-essential \
    libssl-dev \
    libffi-dev \
    pkg-config \
    libxml2-dev \
    libxslt1-dev \
    zlib1g-dev \
    libjpeg-dev \
    libpng-dev

# Make Python 3.11 the default python3
sudo update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.11 1
sudo update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.12 2

echo "2. Stopping ML service..."
pm2 stop napasa-ml-service
pm2 delete napasa-ml-service

echo "3. Creating fresh Python 3.11 environment..."
cd ml_service

# Remove existing venv
rm -rf venv

# Create new virtual environment with Python 3.11
echo "   Creating Python 3.11 virtual environment..."
python3.11 -m venv venv

# Activate virtual environment
echo "   Activating virtual environment..."
source venv/bin/activate

# Verify Python version
echo "   Python version: $(python --version)"

# Upgrade pip and install essential build tools
echo "   Upgrading pip and installing build tools..."
pip install --upgrade pip
pip install --upgrade setuptools wheel

# Install packages in specific order to avoid conflicts
echo "   Installing core packages..."

# Install FastAPI and related packages first
pip install fastapi
pip install uvicorn[standard]

# Install async HTTP client
pip install aiohttp

# Install other essential packages
pip install python-multipart
pip install python-dotenv
pip install schedule
pip install requests
pip install numpy
pip install pandas

# Try to install optional packages (may fail but that's ok)
echo "   Installing optional packages..."
pip install psycopg2-binary || echo "   ⚠️ psycopg2-binary failed (optional)"
pip install redis || echo "   ⚠️ redis failed (optional)"
pip install scikit-learn || echo "   ⚠️ scikit-learn failed (optional)"

# Install from requirements.txt if it exists
if [ -f "requirements.txt" ]; then
    echo "   Installing from requirements.txt..."
    pip install -r requirements.txt || echo "   ⚠️ Some requirements.txt packages failed"
fi

# Test the installation
echo "   Testing package imports..."
python -c "import fastapi; print('✅ FastAPI imported successfully')"
python -c "import uvicorn; print('✅ Uvicorn imported successfully')"
python -c "import aiohttp; print('✅ aiohttp imported successfully')"
python -c "import schedule; print('✅ Schedule imported successfully')"
python -c "import requests; print('✅ Requests imported successfully')"

# Test main.py
echo "   Testing main.py..."
python -c "
try:
    import sys
    sys.path.append('.')
    from main import app
    print('✅ main.py imports successfully')
except Exception as e:
    print(f'❌ main.py import failed: {e}')
    import traceback
    traceback.print_exc()
"

deactivate
cd ..

echo "4. Creating PM2 configuration with Python 3.11..."
cat > ecosystem.ml-python311.config.js << 'EOF'
module.exports = {
  apps: [
    {
      name: 'napasa-ml-service',
      script: 'ml_service/main.py',
      interpreter: 'ml_service/venv/bin/python',
      instances: 1,
      autorestart: true,
      watch: false,
      max_memory_restart: '1G',
      env: {
        NODE_ENV: 'production',
        PORT: 8000,
        HOST: '0.0.0.0'
      },
      error_file: './ml_service/logs/ml-service-err.log',
      out_file: './ml_service/logs/ml-service-out.log',
      log_file: './ml_service/logs/ml-service-combined.log',
      time: true,
      restart_delay: 5000,
      min_uptime: '10s',
      max_restarts: 3
    }
  ]
};
EOF

echo "5. Starting ML service with Python 3.11..."
pm2 start ecosystem.ml-python311.config.js

echo "6. Waiting for service to start..."
sleep 15

echo "7. Checking service status..."
pm2 status

echo "8. Testing ML service..."
sleep 5
echo "   Testing ML service health endpoint..."
if curl -s --connect-timeout 10 http://localhost:8000/health; then
    echo "   ✅ ML Service is responding!"
else
    echo "   ❌ ML Service still not responding"
    echo "   Checking logs..."
    pm2 logs napasa-ml-service --lines 15 --nostream
fi

echo ""
echo "9. Testing all endpoints..."

echo "   Testing AI Backend (direct)..."
if curl -s --connect-timeout 5 http://localhost:3000/health; then
    echo "   ✅ AI Backend direct connection works"
else
    echo "   ❌ AI Backend direct connection failed"
fi

echo "   Testing ML Service (direct)..."
if curl -s --connect-timeout 5 http://localhost:8000/health; then
    echo "   ✅ ML Service direct connection works"
else
    echo "   ❌ ML Service direct connection failed"
fi

echo "   Testing AI Backend (via Nginx)..."
if curl -s --connect-timeout 5 http://localhost/ai/health; then
    echo "   ✅ AI Backend via Nginx works"
else
    echo "   ❌ AI Backend via Nginx failed"
fi

echo "   Testing ML Service (via Nginx)..."
if curl -s --connect-timeout 5 http://localhost/ml/health; then
    echo "   ✅ ML Service via Nginx works"
else
    echo "   ❌ ML Service via Nginx failed"
fi

echo ""
echo "🎉 Python 3.11 compatibility fix completed!"
echo ""
echo "📋 PM2 Status:"
pm2 status
echo ""
echo "📋 Your AI Backend endpoints:"
echo "   🌐 AI Backend: http://13.51.162.253/ai/health"
echo "   🌐 ML Service: http://13.51.162.253/ml/health"
echo "   🌐 Direct AI:  http://13.51.162.253:3000/health"
echo "   🌐 Direct ML:  http://13.51.162.253:8000/health"






