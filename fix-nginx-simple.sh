#!/bin/bash

echo "🔧 Fixing Nginx with Simple Configuration"
echo "========================================"

# Navigate to application directory
cd /opt/napasa-ai-backend

echo "1. Stopping Nginx..."
sudo systemctl stop nginx

echo "2. Creating simple Nginx configuration..."
sudo tee /etc/nginx/sites-available/napasa-ai-backend > /dev/null << 'EOF'
server {
    listen 80 default_server;
    listen [::]:80 default_server;

    server_name _;

    location /ai/ {
        proxy_pass http://127.0.0.1:3000/;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    location /ml/ {
        proxy_pass http://127.0.0.1:8000/;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    # Optional: fallback for root requests
    location / {
        return 404;
    }
}
EOF

echo "3. Removing default site and enabling our site..."
# Remove default site
sudo rm -f /etc/nginx/sites-enabled/default

# Enable our site
sudo ln -sf /etc/nginx/sites-available/napasa-ai-backend /etc/nginx/sites-enabled/

echo "4. Testing Nginx configuration..."
sudo nginx -t

if [ $? -eq 0 ]; then
    echo "   ✅ Nginx configuration is valid!"
    sudo systemctl start nginx
    sudo systemctl enable nginx
    echo "   ✅ Nginx started and enabled!"
else
    echo "   ❌ Nginx configuration has errors"
    echo "   Let's check what's wrong..."
    sudo nginx -T | grep -A 5 -B 5 "location"
fi

echo ""
echo "5. Checking Nginx status..."
sudo systemctl status nginx --no-pager -l

echo ""
echo "6. Testing direct connections first..."

echo "   Testing AI Backend (direct)..."
if curl -s --connect-timeout 5 http://127.0.0.1:3000/health; then
    echo "   ✅ AI Backend direct connection works"
else
    echo "   ❌ AI Backend direct connection failed"
fi

echo "   Testing ML Service (direct)..."
if curl -s --connect-timeout 5 http://127.0.0.1:8000/health; then
    echo "   ✅ ML Service direct connection works"
else
    echo "   ❌ ML Service direct connection failed"
fi

echo ""
echo "7. Testing Nginx proxy routes..."

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
echo "8. Testing external access..."

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
echo "9. Checking ports and processes..."

echo "   Checking if port 80 is open..."
sudo netstat -tlnp | grep :80

echo "   Checking if port 3000 is open..."
sudo netstat -tlnp | grep :3000

echo "   Checking if port 8000 is open..."
sudo netstat -tlnp | grep :8000

echo ""
echo "10. Checking PM2 status..."
pm2 status

echo ""
echo "🎉 Simple Nginx configuration fix completed!"
echo ""
echo "📋 Your AI Backend endpoints:"
echo "   🌐 AI Backend: http://13.51.162.253/ai/health"
echo "   🌐 ML Service: http://13.51.162.253/ml/health"
echo "   🌐 Direct AI:  http://13.51.162.253:3000/health"
echo "   🌐 Direct ML:  http://13.51.162.253:8000/health"




