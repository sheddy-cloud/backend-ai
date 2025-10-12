#!/bin/bash

# NAPASA AI Backend EC2 Docker Deployment Script
# Alternative containerized deployment

echo "🐳 Starting NAPASA AI Backend Docker Deployment on EC2..."

# Update system packages
echo "📦 Updating system packages..."
sudo apt update && sudo apt upgrade -y

# Install Docker and Docker Compose
if ! command -v docker &> /dev/null; then
    echo "📦 Installing Docker..."
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh
    sudo usermod -aG docker $USER
    rm get-docker.sh
fi

if ! command -v docker-compose &> /dev/null; then
    echo "📦 Installing Docker Compose..."
    sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
fi

# Install Git (if not already installed)
if ! command -v git &> /dev/null; then
    echo "📦 Installing Git..."
    sudo apt install -y git
fi

# Install Nginx (if not already installed)
if ! command -v nginx &> /dev/null; then
    echo "📦 Installing Nginx..."
    sudo apt install -y nginx
fi

# Create application directory
echo "📁 Setting up application directory..."
sudo mkdir -p /opt/napasa-ai-backend
sudo chown $USER:$USER /opt/napasa-ai-backend
cd /opt/napasa-ai-backend

# Copy environment files
echo "⚙️ Setting up environment..."
if [ ! -f ".env" ]; then
    cp env.production .env
    echo "✅ Environment file created from template"
fi

# Create necessary directories
echo "📁 Creating directories..."
mkdir -p uploads logs ml_service/logs ml_service/models
chmod 755 uploads logs ml_service/logs ml_service/models

# Build and start containers
echo "🐳 Building and starting Docker containers..."
docker-compose -f docker-compose.prod.yml build
docker-compose -f docker-compose.prod.yml up -d

# Wait for services to be ready
echo "⏳ Waiting for services to start..."
sleep 30

# Check container status
echo "📊 Container status:"
docker-compose -f docker-compose.prod.yml ps

# Configure Nginx for Docker deployment
echo "⚙️ Configuring Nginx for Docker deployment..."

# Remove existing configuration if it exists
sudo rm -f /etc/nginx/sites-available/napasa-ai-backend
sudo rm -f /etc/nginx/sites-enabled/napasa-ai-backend

sudo tee /etc/nginx/sites-available/napasa-ai-backend > /dev/null << 'EOF'
server {
    listen 80;
    server_name 13.51.162.253;

    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header Referrer-Policy "no-referrer-when-downgrade" always;
    add_header Content-Security-Policy "default-src 'self' http: https: data: blob: 'unsafe-inline'" always;

    # Gzip compression
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_proxied expired no-cache no-store private auth;
    gzip_types text/plain text/css text/xml text/javascript application/x-javascript application/xml+rss application/javascript;

    # Rate limiting
    limit_req_zone $binary_remote_addr zone=ai_api:10m rate=10r/s;
    limit_req_zone $binary_remote_addr zone=ml_api:10m rate=5r/s;

    # AI Backend API routes (Docker containers)
    location /ai/api/ {
        limit_req zone=ai_api burst=20 nodelay;
        proxy_pass http://localhost:3000/api/;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
        proxy_read_timeout 300s;
        proxy_connect_timeout 75s;
    }

    # ML Service API routes (Docker containers)
    location /ml/ {
        limit_req zone=ml_api burst=10 nodelay;
        proxy_pass http://localhost:8000/;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
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
        
        # Security for uploads
        location ~* \.(php|jsp|asp|sh|cgi)$ {
            deny all;
        }
    }

    # Default location (AI backend)
    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
    }
}
EOF

# Enable the site
sudo ln -sf /etc/nginx/sites-available/napasa-ai-backend /etc/nginx/sites-enabled/

# Test Nginx configuration
echo "🔍 Testing Nginx configuration..."
sudo nginx -t

if [ $? -eq 0 ]; then
    echo "✅ Nginx configuration is valid"
    
    # Start and enable Nginx
    sudo systemctl start nginx
    sudo systemctl enable nginx
    sudo systemctl reload nginx
    
    echo "✅ Nginx started and enabled"
else
    echo "❌ Nginx configuration has errors"
    exit 1
fi

echo "✅ Docker deployment completed!"
echo "🌐 Your AI Backend is now available at:"
echo "   - AI Backend: http://13.51.162.253/ai/api"
echo "   - ML Service: http://13.51.162.253/ml"
echo "🏥 Health checks:"
echo "   - AI Backend: http://13.51.162.253/ai/health"
echo "   - ML Service: http://13.51.162.253/ml/health"
echo ""
echo "📋 Useful Docker commands:"
echo "  docker-compose -f docker-compose.prod.yml ps     # Check container status"
echo "  docker-compose -f docker-compose.prod.yml logs   # View logs"
echo "  docker-compose -f docker-compose.prod.yml restart # Restart services"
echo "  docker-compose -f docker-compose.prod.yml down   # Stop services"
echo "  docker-compose -f docker-compose.prod.yml up -d  # Start services"
echo ""
echo "⚠️ Don't forget to:"
echo "  1. Configure your EC2 security group to allow ports 80, 3000, and 8000"
echo "  2. Update your Flutter app to use the AI endpoints"
echo "  3. Edit .env file with your actual configuration"




