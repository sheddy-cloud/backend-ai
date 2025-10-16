#!/bin/bash

echo "🔧 Fixing NAPASA AI Backend Issues"
echo "=================================="

# Navigate to application directory
cd /opt/napasa-ai-backend

echo "1. Fixing ML Service issue..."

# Check ML service logs
echo "   Checking ML service logs..."
pm2 logs napasa-ml-service --lines 10 --nostream

# Check if Python virtual environment exists
if [ ! -d "ml_service/venv" ]; then
    echo "   Creating Python virtual environment..."
    cd ml_service
    python3 -m venv venv
    source venv/bin/activate
    pip install --upgrade pip
    pip install -r requirements.txt
    deactivate
    cd ..
fi

# Check if main.py exists and is executable
if [ -f "ml_service/main.py" ]; then
    echo "   ML service main.py exists"
    # Make sure it's executable
    chmod +x ml_service/main.py
else
    echo "   ❌ ML service main.py not found"
    ls -la ml_service/
fi

# Check environment file for ML service
if [ ! -f "ml_service/.env" ]; then
    echo "   Creating ML service environment file..."
    cat > ml_service/.env << 'EOF'
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
fi

echo ""
echo "2. Fixing Nginx configuration..."

# Remove the incorrectly added rate limiting zones from nginx.conf
echo "   Removing incorrect rate limiting zones from nginx.conf..."
sudo sed -i '/# Rate limiting zones for AI backend/,+2d' /etc/nginx/nginx.conf

# Create a simple nginx configuration without rate limiting
echo "   Creating simple Nginx configuration..."
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
    location /ai/api/ {
        proxy_pass http://localhost:3000/api/;
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

    # Health check endpoints
    location /ai/health {
        proxy_pass http://localhost:3000/health;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    location /ml/health {
        proxy_pass http://localhost:8000/health;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    # Static files (uploads) with caching
    location /ai/uploads/ {
        alias /opt/napasa-ai-backend/uploads/;
        expires 1y;
        add_header Cache-Control "public, immutable";
        add_header X-Content-Type-Options "nosniff";
    }

    # Default location
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
    echo "   ✅ Nginx configuration is valid"
    sudo systemctl reload nginx
    echo "   ✅ Nginx reloaded successfully"
else
    echo "   ❌ Nginx configuration still has errors"
    echo "   Let's check the main nginx.conf file..."
    sudo nginx -T | head -20
fi

echo ""
echo "3. Restarting services..."

# Stop and restart PM2 processes
pm2 stop napasa-ai-backend
pm2 stop napasa-ml-service
pm2 delete napasa-ai-backend
pm2 delete napasa-ml-service

# Start them again
pm2 start ecosystem.config.js

echo ""
echo "4. Checking service status..."
sleep 5
pm2 status

echo ""
echo "5. Testing connections..."

echo "   Testing AI Backend..."
if curl -s --connect-timeout 5 http://localhost:3000/health; then
    echo "   ✅ AI Backend is responding"
else
    echo "   ❌ AI Backend is not responding"
    echo "   AI Backend logs:"
    pm2 logs napasa-ai-backend --lines 5 --nostream
fi

echo ""
echo "   Testing ML Service..."
if curl -s --connect-timeout 5 http://localhost:8000/health; then
    echo "   ✅ ML Service is responding"
else
    echo "   ❌ ML Service is not responding"
    echo "   ML Service logs:"
    pm2 logs napasa-ml-service --lines 10 --nostream
fi

echo ""
echo "   Testing Nginx..."
if curl -s --connect-timeout 5 http://localhost/ai/health; then
    echo "   ✅ Nginx is proxying to AI Backend"
else
    echo "   ❌ Nginx is not working properly"
fi

echo ""
echo "🎉 Fix completed!"
echo ""
echo "📋 Test your endpoints:"
echo "curl http://13.51.162.253:3000/health  # Direct to AI Backend"
echo "curl http://13.51.162.253:8000/health  # Direct to ML Service"
echo "curl http://13.51.162.253/ai/health    # Via Nginx to AI Backend"
echo "curl http://13.51.162.253/ml/health    # Via Nginx to ML Service"
echo ""
echo "📋 Useful commands:"
echo "pm2 status                    # Check app status"
echo "pm2 logs napasa-ai-backend    # View AI backend logs"
echo "pm2 logs napasa-ml-service    # View ML service logs"
echo "sudo systemctl status nginx   # Check Nginx"







