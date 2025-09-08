#!/bin/bash

echo "🔧 Fixing Nginx Location Blocks"
echo "==============================="

# Navigate to application directory
cd /opt/napasa-ai-backend

echo "1. Checking current Nginx configuration..."
echo "   Current site configuration:"
sudo cat /etc/nginx/sites-available/napasa-ai-backend

echo ""
echo "2. Checking if Nginx site is enabled..."
ls -la /etc/nginx/sites-enabled/ | grep napasa

echo ""
echo "3. Creating proper Nginx configuration with location blocks..."

# Create the correct Nginx configuration with proper location blocks
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

echo "4. Enabling the Nginx site..."
# Remove default site if it exists
sudo rm -f /etc/nginx/sites-enabled/default

# Enable our site
sudo ln -sf /etc/nginx/sites-available/napasa-ai-backend /etc/nginx/sites-enabled/

echo "5. Testing Nginx configuration..."
sudo nginx -t

if [ $? -eq 0 ]; then
    echo "   ✅ Nginx configuration is valid!"
    sudo systemctl reload nginx
    echo "   ✅ Nginx reloaded successfully!"
else
    echo "   ❌ Nginx configuration has errors"
    echo "   Let's check what's wrong..."
    sudo nginx -T | grep -A 5 -B 5 "location"
fi

echo ""
echo "6. Checking Nginx status..."
sudo systemctl status nginx --no-pager -l

echo ""
echo "7. Testing direct connections first..."

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

echo ""
echo "8. Testing Nginx proxy routes..."

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
echo "9. Testing external access..."

echo "   Testing AI Backend (external)..."
if curl -s --connect-timeout 10 http://13.51.162.253/ai/health; then
    echo "   ✅ AI Backend external access works"
else
    echo "   ❌ AI Backend external access failed"
fi

echo "   Testing ML Service (external)..."
if curl -s --connect-timeout 10 http://13.51.162.253/ml/health; then
    echo "   ✅ ML Service external access works"
else
    echo "   ❌ ML Service external access failed"
fi

echo ""
echo "10. Checking firewall and security groups..."
echo "   Checking if port 80 is open..."
sudo netstat -tlnp | grep :80

echo "   Checking if port 3000 is open..."
sudo netstat -tlnp | grep :3000

echo "   Checking if port 8000 is open..."
sudo netstat -tlnp | grep :8000

echo ""
echo "🎉 Nginx location blocks fix completed!"
echo ""
echo "📋 PM2 Status:"
pm2 status
echo ""
echo "📋 Your AI Backend endpoints:"
echo "   🌐 AI Backend: http://13.51.162.253/ai/health"
echo "   🌐 ML Service: http://13.51.162.253/ml/health"
echo "   🌐 Direct AI:  http://13.51.162.253:3000/health"
echo "   🌐 Direct ML:  http://13.51.162.253:8000/health"
