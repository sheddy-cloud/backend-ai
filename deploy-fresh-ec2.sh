#!/bin/bash

echo "🚀 Deploying NAPASA AI Backend to Fresh EC2 Instance"
echo "=================================================="
echo "Instance IP: 16.171.29.165"
echo ""

# Update system
echo "1. Updating system packages..."
sudo apt update && sudo apt upgrade -y

# Install essential packages
echo "2. Installing essential packages..."
sudo apt install -y \
    curl \
    wget \
    git \
    build-essential \
    software-properties-common \
    net-tools \
    htop \
    unzip

# Install Node.js 18
echo "3. Installing Node.js 18..."
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt install -y nodejs

# Install Python 3.11 (stable version)
echo "4. Installing Python 3.11..."
sudo add-apt-repository -y ppa:deadsnakes/ppa
sudo apt update
sudo apt install -y \
    python3.11 \
    python3.11-dev \
    python3.11-venv \
    python3.11-distutils \
    python3-pip \
    libssl-dev \
    libffi-dev \
    pkg-config \
    libxml2-dev \
    libxslt1-dev \
    zlib1g-dev \
    libjpeg-dev \
    libpng-dev

# Install PM2
echo "5. Installing PM2..."
sudo npm install -g pm2

# Install Nginx
echo "6. Installing Nginx..."
sudo apt install -y nginx

# Create application directory
echo "7. Setting up application directory..."
sudo mkdir -p /var/www/napasa-ai-backend
sudo chown -R ubuntu:ubuntu /var/www/napasa-ai-backend

# Copy application files (assuming we're running from the backend-ai folder)
echo "8. Copying application files..."
cp -r . /var/www/napasa-ai-backend/
cd /var/www/napasa-ai-backend

# Install Node.js dependencies
echo "9. Installing Node.js dependencies..."
npm install

# Set up Python environment
echo "10. Setting up Python environment..."
cd ml_service
python3.11 -m venv venv
source venv/bin/activate
pip install --upgrade pip
pip install --upgrade setuptools wheel

# Install Python packages
echo "11. Installing Python packages..."
pip install fastapi
pip install uvicorn[standard]
pip install aiohttp
pip install python-multipart
pip install python-dotenv
pip install schedule
pip install requests
pip install numpy
pip install pandas

# Test Python installation
echo "12. Testing Python installation..."
python -c "import fastapi; print('✅ FastAPI installed')"
python -c "import uvicorn; print('✅ Uvicorn installed')"
python -c "import aiohttp; print('✅ aiohttp installed')"

deactivate
cd ..

# Create environment files
echo "13. Creating environment files..."
cat > .env << 'EOF'
NODE_ENV=production
PORT=3000
HOST=0.0.0.0
DB_HOST=localhost
DB_PORT=5432
DB_NAME=ai_safari_db
DB_USER=napasa_user
DB_PASSWORD=napasa_password
REDIS_HOST=localhost
REDIS_PORT=6379
JWT_SECRET=your-super-secret-jwt-key-change-this-in-production
EOF

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

# Create PM2 ecosystem file
echo "14. Creating PM2 configuration..."
cat > ecosystem.config.js << 'EOF'
module.exports = {
  apps: [
    {
      name: 'napasa-ai-backend',
      script: 'src/server.js',
      instances: 1,
      autorestart: true,
      watch: false,
      max_memory_restart: '1G',
      env: {
        NODE_ENV: 'production',
        PORT: 3000,
        HOST: '0.0.0.0'
      },
      error_file: './logs/ai-backend-err.log',
      out_file: './logs/ai-backend-out.log',
      log_file: './logs/ai-backend-combined.log',
      time: true
    },
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

# Create logs and uploads directories
mkdir -p logs
mkdir -p ml_service/logs
mkdir -p uploads

# Start applications with PM2
echo "15. Starting applications with PM2..."
pm2 start ecosystem.config.js

# Save PM2 configuration
pm2 save

# Setup PM2 startup
pm2 startup

echo "16. Configuring Nginx..."
# Copy our updated nginx configuration
sudo cp nginx.conf /etc/nginx/sites-available/napasa-ai-backend

# Enable the site
sudo rm -f /etc/nginx/sites-enabled/default
sudo ln -sf /etc/nginx/sites-available/napasa-ai-backend /etc/nginx/sites-enabled/

# Test and start Nginx
sudo nginx -t
sudo systemctl restart nginx
sudo systemctl enable nginx

# Configure firewall
echo "17. Configuring firewall..."
sudo ufw allow ssh
sudo ufw allow 80/tcp
sudo ufw allow 3000/tcp
sudo ufw allow 8000/tcp
sudo ufw --force enable

# Wait for services to start
echo "18. Waiting for services to start..."
sleep 15

# Test services
echo "19. Testing services..."
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

# Show status
echo ""
echo "20. Final status check..."
pm2 status

echo ""
echo "🎉 Deployment completed!"
echo ""
echo "📋 Your AI Backend endpoints:"
echo "   🌐 AI Backend: http://16.171.29.165/ai/health"
echo "   🌐 ML Service: http://16.171.29.165/ml/health"
echo "   🌐 Direct AI:  http://16.171.29.165:3000/health"
echo "   🌐 Direct ML:  http://16.171.29.165:8000/health"
echo ""
echo "📋 Next steps:"
echo "   1. Update EC2 Security Groups in AWS Console"
echo "   2. Open ports: 80, 3000, 8000 (Source: 0.0.0.0/0)"
echo "   3. Test external access"
echo ""
echo "📋 Useful commands:"
echo "   pm2 status                    # Check app status"
echo "   pm2 logs napasa-ai-backend    # View AI backend logs"
echo "   pm2 logs napasa-ml-service    # View ML service logs"
echo "   sudo systemctl status nginx   # Check Nginx"




