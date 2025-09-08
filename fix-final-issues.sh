#!/bin/bash

echo "🔧 Fixing Final AI Backend Issues"
echo "================================="

# Navigate to application directory
cd /opt/napasa-ai-backend

echo "1. Checking ML Service status and logs..."
pm2 status
echo ""
echo "ML Service logs:"
pm2 logs napasa-ml-service --lines 15 --nostream

echo ""
echo "2. Fixing ML Service..."

# Stop and delete the errored ML service
pm2 stop napasa-ml-service
pm2 delete napasa-ml-service

# Check if ML service files exist
echo "   Checking ML service files..."
ls -la ml_service/
echo ""
echo "   Checking main.py content:"
head -10 ml_service/main.py

# Recreate Python environment
echo "   Recreating Python environment..."
cd ml_service
rm -rf venv
python3 -m venv venv
source venv/bin/activate

# Install essential packages
echo "   Installing essential packages..."
pip install --upgrade pip
pip install fastapi uvicorn python-multipart python-dotenv

# Test if main.py can be imported
echo "   Testing main.py import..."
python -c "
try:
    import sys
    sys.path.append('.')
    from main import app
    print('✅ main.py imports successfully')
except Exception as e:
    print(f'❌ main.py import failed: {e}')
"

deactivate
cd ..

echo ""
echo "3. Starting ML Service with simple configuration..."

# Create a simple PM2 config for ML service only
cat > ecosystem.ml-only.config.js << 'EOF'
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

# Start ML service
pm2 start ecosystem.ml-only.config.js

echo ""
echo "4. Waiting for ML service to start..."
sleep 10

echo ""
echo "5. Checking service status..."
pm2 status

echo ""
echo "6. Testing ML Service directly..."
sleep 5
if curl -s --connect-timeout 10 http://localhost:8000/health; then
    echo "   ✅ ML Service is now responding!"
else
    echo "   ❌ ML Service still not responding"
    echo "   Latest logs:"
    pm2 logs napasa-ml-service --lines 10 --nostream
fi

echo ""
echo "7. Fixing Nginx routes..."

# Check current Nginx configuration
echo "   Current Nginx site configuration:"
sudo cat /etc/nginx/sites-available/napasa-ai-backend | grep -A 5 -B 5 "location"

# Create corrected Nginx configuration
echo "   Creating corrected Nginx configuration..."
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

    # AI Backend API routes
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

    # ML Service API routes
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
echo "8. Final testing..."

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
echo "🎉 Final fix completed!"
echo ""
echo "📋 PM2 Status:"
pm2 status
echo ""
echo "📋 Your AI Backend endpoints:"
echo "   🌐 AI Backend: http://13.51.162.253/ai/health"
echo "   🌐 ML Service: http://13.51.162.253/ml/health"
echo "   🌐 Direct AI:  http://13.51.162.253:3000/health"
echo "   🌐 Direct ML:  http://13.51.162.253:8000/health"
