#!/bin/bash

echo "🔧 NAPASA AI Backend Quick Fix Script"
echo "====================================="

# Navigate to application directory
cd /opt/napasa-ai-backend

echo "1. Checking if we're in the right directory..."
if [ ! -f "ecosystem.config.js" ]; then
    echo "❌ ecosystem.config.js not found. Please run the full deployment script first."
    exit 1
fi
echo "✅ Found ecosystem.config.js"

echo ""
echo "2. Installing dependencies..."
npm install --production

echo ""
echo "3. Setting up Python ML service..."
cd ml_service
if [ ! -d "venv" ]; then
    python3 -m venv venv
fi
source venv/bin/activate
pip install --upgrade pip
pip install -r requirements.txt
deactivate
cd ..

echo ""
echo "4. Setting up environment file..."
if [ ! -f ".env" ]; then
    if [ -f "env.production" ]; then
        cp env.production .env
        echo "✅ Created .env from env.production"
    else
        echo "❌ No environment file found. Creating basic .env..."
        cat > .env << 'EOF'
PORT=3000
NODE_ENV=production
HOST=0.0.0.0
DB_HOST=localhost
DB_PORT=5432
DB_NAME=ai_safari_db
DB_USER=napasa_user
DB_PASSWORD=napasa_password
REDIS_HOST=localhost
REDIS_PORT=6379
ML_SERVICE_URL=http://localhost:8000
JWT_SECRET=napasa_ai_production_jwt_secret_2024_secure_key
CORS_ORIGIN=http://13.51.162.253,http://localhost:3000
LOG_LEVEL=info
EOF
        echo "✅ Created basic .env file"
    fi
else
    echo "✅ .env file already exists"
fi

echo ""
echo "5. Creating directories..."
mkdir -p uploads logs ml_service/logs ml_service/models
chmod 755 uploads logs ml_service/logs ml_service/models

echo ""
echo "6. Starting applications with PM2..."
pm2 stop napasa-ai-backend 2>/dev/null || true
pm2 stop napasa-ml-service 2>/dev/null || true
pm2 delete napasa-ai-backend 2>/dev/null || true
pm2 delete napasa-ml-service 2>/dev/null || true
pm2 start ecosystem.config.js

echo ""
echo "7. Checking PM2 status..."
pm2 status

echo ""
echo "8. Fixing Nginx configuration..."

# Add rate limiting zones to main nginx.conf if not already present
if ! grep -q "limit_req_zone.*ai_api" /etc/nginx/nginx.conf; then
    echo "Adding rate limiting zones to main nginx.conf..."
    sudo tee -a /etc/nginx/nginx.conf > /dev/null << 'EOF'

# Rate limiting zones for AI backend
limit_req_zone $binary_remote_addr zone=ai_api:10m rate=10r/s;
limit_req_zone $binary_remote_addr zone=ml_api:10m rate=5r/s;
EOF
fi

# Remove the problematic rate limiting zones from site config
sudo sed -i '/limit_req_zone/d' /etc/nginx/sites-available/napasa-ai-backend 2>/dev/null || true

echo ""
echo "9. Testing Nginx configuration..."
sudo nginx -t

if [ $? -eq 0 ]; then
    echo "✅ Nginx configuration is valid"
    sudo systemctl reload nginx
    echo "✅ Nginx reloaded"
else
    echo "❌ Nginx configuration still has errors"
    echo "Let's create a simple configuration without rate limiting..."
    
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
    }

    # ML Service API routes
    location /ml/ {
        proxy_pass http://localhost:8000/;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    # Health check endpoints
    location /ai/health {
        proxy_pass http://localhost:3000/health;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
    }

    location /ml/health {
        proxy_pass http://localhost:8000/health;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
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

    sudo nginx -t
    if [ $? -eq 0 ]; then
        echo "✅ Simple Nginx configuration is valid"
        sudo systemctl reload nginx
        echo "✅ Nginx reloaded with simple configuration"
    else
        echo "❌ Still having Nginx issues. Please check manually."
    fi
fi

echo ""
echo "10. Testing local connections..."
sleep 3

echo "   Testing AI Backend localhost:3000..."
if curl -s --connect-timeout 5 http://localhost:3000/health; then
    echo "   ✅ AI Backend responds on localhost:3000"
else
    echo "   ❌ AI Backend does not respond on localhost:3000"
    echo "   Checking logs..."
    pm2 logs napasa-ai-backend --lines 5 --nostream
fi

echo "   Testing ML Service localhost:8000..."
if curl -s --connect-timeout 5 http://localhost:8000/health; then
    echo "   ✅ ML Service responds on localhost:8000"
else
    echo "   ❌ ML Service does not respond on localhost:8000"
    echo "   Checking logs..."
    pm2 logs napasa-ml-service --lines 5 --nostream
fi

echo "   Testing Nginx localhost:80..."
if curl -s --connect-timeout 5 http://localhost/ai/health; then
    echo "   ✅ Nginx is working and proxying to AI backend"
else
    echo "   ❌ Nginx is not working properly"
fi

echo ""
echo "🎉 Quick fix completed!"
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




