#!/bin/bash

echo "🔧 Fixing Python Virtual Environment & ML Service"
echo "================================================="

# Navigate to application directory
cd /opt/napasa-ai-backend

echo "1. Installing Python venv package..."
sudo apt update
sudo apt install -y python3.12-venv python3-pip

echo "2. Stopping ML service..."
pm2 stop napasa-ml-service
pm2 delete napasa-ml-service

echo "3. Setting up Python virtual environment properly..."
cd ml_service

# Remove existing venv
rm -rf venv

# Create new virtual environment
echo "   Creating Python virtual environment..."
python3 -m venv venv

# Activate virtual environment
echo "   Activating virtual environment..."
source venv/bin/activate

# Upgrade pip
echo "   Upgrading pip..."
pip install --upgrade pip

# Install FastAPI and dependencies
echo "   Installing FastAPI and dependencies..."
pip install fastapi
pip install uvicorn[standard]
pip install python-multipart
pip install python-dotenv
pip install psycopg2-binary
pip install redis
pip install requests
pip install numpy
pip install pandas
pip install scikit-learn

# Install from requirements.txt if it exists
if [ -f "requirements.txt" ]; then
    echo "   Installing from requirements.txt..."
    pip install -r requirements.txt
fi

# Test the installation
echo "   Testing FastAPI installation..."
python -c "import fastapi; print('✅ FastAPI installed successfully')"
python -c "import uvicorn; print('✅ Uvicorn installed successfully')"

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

echo "4. Creating proper PM2 configuration..."
cat > ecosystem.ml-fixed.config.js << 'EOF'
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

echo "5. Starting ML service..."
pm2 start ecosystem.ml-fixed.config.js

echo "6. Waiting for service to start..."
sleep 10

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
    pm2 logs napasa-ml-service --lines 10 --nostream
fi

echo ""
echo "9. Fixing Nginx routes (correcting the 404 issue)..."

# The issue is that the AI backend doesn't have a /health endpoint at root
# Let's check what endpoints the AI backend actually has
echo "   Checking AI backend endpoints..."
curl -s http://localhost:3000/ | head -5

# Create corrected Nginx configuration with proper route handling
sudo tee /etc/nginx/sites-available/napasa-ai-backend > /dev/null << 'EOF'
server {
    listen 80;
    server_name 13.51.162.253;

    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header X-Content-Type-Options "nosniff" always;

    # Gzip compression
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_types text/plain text/css text/xml text/javascript application/x-javascript application/xml+rss application/javascript;

    # AI Backend API routes - exact path matching
    location = /ai/health {
        proxy_pass http://localhost:3000/health;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    location /ai/ {
        proxy_pass http://localhost:3000/;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_read_timeout 300s;
        proxy_connect_timeout 75s;
    }

    # ML Service API routes - exact path matching
    location = /ml/health {
        proxy_pass http://localhost:8000/health;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    location /ml/ {
        proxy_pass http://localhost:8000/;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_read_timeout 300s;
        proxy_connect_timeout 75s;
    }

    # Static files (uploads) with caching
    location /ai/uploads/ {
        alias /opt/napasa-ai-backend/uploads/;
        expires 1y;
        add_header Cache-Control "public, immutable";
        add_header X-Content-Type-Options "nosniff";
    }

    # Default location - redirect to AI backend
    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
EOF

# Test Nginx configuration
echo "   Testing Nginx configuration..."
sudo nginx -t

if [ $? -eq 0 ]; then
    echo "   ✅ Nginx configuration is valid!"
    sudo systemctl reload nginx
    echo "   ✅ Nginx reloaded successfully!"
else
    echo "   ❌ Nginx configuration has errors"
fi

echo ""
echo "10. Final comprehensive testing..."

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
echo "🎉 Python venv and ML Service fix completed!"
echo ""
echo "📋 PM2 Status:"
pm2 status
echo ""
echo "📋 Your AI Backend endpoints:"
echo "   🌐 AI Backend: http://13.51.162.253/ai/health"
echo "   🌐 ML Service: http://13.51.162.253/ml/health"
echo "   🌐 Direct AI:  http://13.51.162.253:3000/health"
echo "   🌐 Direct ML:  http://13.51.162.253:8000/health"



