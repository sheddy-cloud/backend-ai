#!/bin/bash

# NAPASA AI Backend EC2 Docker Deployment Script
# Simple Docker deployment with fallback data

echo "🐳 Starting NAPASA AI Backend Docker Deployment on EC2..."
echo "Instance IP: 16.171.29.165"
echo ""

# Update system packages
echo "1. Updating system packages..."
sudo apt update && sudo apt upgrade -y

# Install Docker and Docker Compose
echo "2. Installing Docker..."
if ! command -v docker &> /dev/null; then
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh
    sudo usermod -aG docker $USER
    rm get-docker.sh
    echo "✅ Docker installed"
else
    echo "✅ Docker already installed"
fi

if ! command -v docker-compose &> /dev/null; then
    echo "Installing Docker Compose..."
    sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
    echo "✅ Docker Compose installed"
else
    echo "✅ Docker Compose already installed"
fi

# Install Nginx
echo "3. Installing Nginx..."
if ! command -v nginx &> /dev/null; then
    sudo apt install -y nginx
    echo "✅ Nginx installed"
else
    echo "✅ Nginx already installed"
fi

# Create application directory
echo "4. Setting up application directory..."
sudo mkdir -p /opt/napasa-ai-backend
sudo chown $USER:$USER /opt/napasa-ai-backend
cd /opt/napasa-ai-backend

# Copy application files (assuming we're running from the backend-ai folder)
echo "5. Copying application files..."
cp -r . /opt/napasa-ai-backend/
cd /opt/napasa-ai-backend

# Create environment file
echo "6. Creating environment configuration..."
cat > .env << 'EOF'
NODE_ENV=production
PORT=3000
HOST=0.0.0.0
DB_HOST=postgres
DB_PORT=5432
DB_NAME=ai_safari_db
DB_USER=napasa
DB_PASSWORD=12345678
REDIS_HOST=redis
REDIS_PORT=6379
JWT_SECRET=your-super-secret-jwt-key-change-this-in-production
EOF

# Create necessary directories
echo "7. Creating directories..."
mkdir -p uploads logs ml_service/logs ml_service/models
chmod 755 uploads logs ml_service/logs ml_service/models

# Build and start containers
echo "8. Building and starting Docker containers..."
docker-compose -f docker-compose.prod.yml build --no-cache
docker-compose -f docker-compose.prod.yml up -d

# Wait for services to be ready
echo "9. Waiting for services to start..."
sleep 45

# Check container status
echo "10. Checking container status..."
docker-compose -f docker-compose.prod.yml ps

# Configure Nginx
echo "11. Configuring Nginx..."
sudo rm -f /etc/nginx/sites-enabled/default

sudo tee /etc/nginx/sites-available/napasa-ai-backend > /dev/null << 'EOF'
server {
    listen 80 default_server;
    listen [::]:80 default_server;

    server_name _;

    # AI Backend API routes
    location /ai/ {
        proxy_pass http://127.0.0.1:3000/;
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
        proxy_pass http://127.0.0.1:8000/;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_read_timeout 300s;
        proxy_connect_timeout 75s;
    }

    # Fallback for root requests
    location / {
        return 404;
    }
}
EOF

# Enable the site
sudo ln -sf /etc/nginx/sites-available/napasa-ai-backend /etc/nginx/sites-enabled/

# Test and start Nginx
echo "12. Starting Nginx..."
sudo nginx -t
sudo systemctl restart nginx
sudo systemctl enable nginx

# Configure firewall
echo "13. Configuring firewall..."
sudo ufw allow ssh
sudo ufw allow 80/tcp
sudo ufw allow 3000/tcp
sudo ufw allow 8000/tcp
sudo ufw --force enable

# Wait for services to start
echo "14. Waiting for services to start..."
sleep 15

# Test services
echo "15. Testing services..."
echo "   Testing AI Backend (via Nginx)..."
if curl -s --connect-timeout 10 http://localhost/ai/health; then
    echo "   ✅ AI Backend via Nginx works"
else
    echo "   ❌ AI Backend via Nginx failed"
fi

echo "   Testing ML Service (via Nginx)..."
if curl -s --connect-timeout 10 http://localhost/ml/health; then
    echo "   ✅ ML Service via Nginx works"
else
    echo "   ❌ ML Service via Nginx failed"
fi

echo "   Testing API endpoint..."
if curl -s --connect-timeout 10 http://localhost/ai/api/wildlife/predictions/serengeti; then
    echo "   ✅ API endpoint works"
else
    echo "   ❌ API endpoint failed"
fi

# Show status
echo ""
echo "16. Final status check..."
docker-compose -f docker-compose.prod.yml ps

echo ""
echo "🎉 Docker deployment completed!"
echo ""
echo "📋 Your AI Backend endpoints:"
echo "   🌐 AI Backend: http://16.171.29.165/ai/health"
echo "   🌐 ML Service: http://16.171.29.165/ml/health"
echo "   🌐 API Test:   http://16.171.29.165/ai/api/wildlife/predictions/serengeti"
echo ""
echo "📋 Useful Docker commands:"
echo "   docker-compose -f docker-compose.prod.yml ps                    # Check status"
echo "   docker-compose -f docker-compose.prod.yml logs ai-backend      # View AI backend logs"
echo "   docker-compose -f docker-compose.prod.yml logs ml-service      # View ML service logs"
echo "   docker-compose -f docker-compose.prod.yml restart              # Restart all services"
echo "   docker-compose -f docker-compose.prod.yml down                 # Stop all services"
echo "   docker-compose -f docker-compose.prod.yml up -d                # Start all services"
echo ""
echo "📋 Next steps:"
echo "   1. Update EC2 Security Groups in AWS Console"
echo "   2. Open ports: 80, 3000, 8000 (Source: 0.0.0.0/0)"
echo "   3. Test external access"
echo "   4. Your Flutter app should now connect successfully!"



