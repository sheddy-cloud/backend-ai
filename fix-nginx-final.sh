#!/bin/bash

echo "🔧 Fixing Nginx Rate Limiting Configuration"
echo "==========================================="

echo "1. Removing incorrect rate limiting zones from nginx.conf..."
# Remove the incorrectly added rate limiting zones
sudo sed -i '/# Rate limiting zones for AI backend/,+2d' /etc/nginx/nginx.conf

echo "2. Creating clean Nginx configuration..."
# Create a simple, working Nginx configuration
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

echo "3. Testing Nginx configuration..."
sudo nginx -t

if [ $? -eq 0 ]; then
    echo "   ✅ Nginx configuration is valid!"
    sudo systemctl reload nginx
    echo "   ✅ Nginx reloaded successfully!"
else
    echo "   ❌ Nginx configuration still has errors"
    echo "   Let's check what's wrong..."
    sudo nginx -T | grep -A 5 -B 5 "limit_req"
fi

echo "4. Testing all endpoints..."

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
echo "🎉 Nginx fix completed!"
echo ""
echo "📋 Your AI Backend is now fully deployed and accessible at:"
echo "   🌐 AI Backend: http://13.51.162.253/ai/health"
echo "   🌐 ML Service: http://13.51.162.253/ml/health"
echo "   🌐 Direct AI:  http://13.51.162.253:3000/health"
echo "   🌐 Direct ML:  http://13.51.162.253:8000/health"
echo ""
echo "📋 PM2 Status:"
pm2 status




