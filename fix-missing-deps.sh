#!/bin/bash

echo "🔧 Fixing Missing Dependencies"
echo "============================="

# Navigate to application directory
cd /opt/napasa-ai-backend

echo "1. Stopping ML service..."
pm2 stop napasa-ml-service

echo "2. Installing missing Python packages..."
cd ml_service
source venv/bin/activate

# Install missing packages
echo "   Installing redis..."
pip install redis

echo "   Installing other potentially missing packages..."
pip install psycopg2-binary
pip install scikit-learn
pip install python-jose[cryptography]
pip install passlib[bcrypt]

# Install from requirements.txt if it exists
if [ -f "requirements.txt" ]; then
    echo "   Installing from requirements.txt..."
    pip install -r requirements.txt
fi

# Test the installation
echo "3. Testing package imports..."
python -c "import redis; print('✅ Redis imported successfully')"
python -c "import redis.asyncio; print('✅ Redis asyncio imported successfully')"

# Test main.py
echo "4. Testing main.py..."
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

echo "5. Starting ML service..."
pm2 start napasa-ml-service

echo "6. Waiting for service to start..."
sleep 10

echo "7. Checking service status..."
pm2 status

echo "8. Testing ML service..."
sleep 5
if curl -s --connect-timeout 10 http://localhost:8000/health; then
    echo "   ✅ ML Service is responding!"
else
    echo "   ❌ ML Service still not responding"
    echo "   Checking logs..."
    pm2 logs napasa-ml-service --lines 10 --nostream
fi

echo ""
echo "🎉 Missing dependencies fix completed!"
echo ""
echo "📋 PM2 Status:"
pm2 status






