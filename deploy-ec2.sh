#!/bin/bash

# NAPASA AI Backend EC2 Deployment Script
# Run this script on your EC2 instance

echo "🚀 Starting NAPASA AI Backend Deployment on EC2..."

# Update system packages
echo "📦 Updating system packages..."
sudo apt update && sudo apt upgrade -y

# Install Node.js (if not already installed)
if ! command -v node &> /dev/null; then
    echo "📦 Installing Node.js..."
    curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
    sudo apt-get install -y nodejs
fi

# Install Python and pip (if not already installed)
if ! command -v python3 &> /dev/null; then
    echo "📦 Installing Python 3..."
    sudo apt install -y python3 python3-pip python3-venv
fi

# Install PM2 for process management
if ! command -v pm2 &> /dev/null; then
    echo "📦 Installing PM2..."
    sudo npm install -g pm2
fi

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

# Install PostgreSQL (if not already installed)
if ! command -v psql &> /dev/null; then
    echo "📦 Installing PostgreSQL..."
    sudo apt install -y postgresql postgresql-contrib
fi

# Install Redis (if not already installed)
if ! command -v redis-server &> /dev/null; then
    echo "📦 Installing Redis..."
    sudo apt install -y redis-server
fi

# Create application directory
echo "📁 Setting up application directory..."
sudo mkdir -p /opt/napasa-ai-backend
sudo chown $USER:$USER /opt/napasa-ai-backend

# Copy files to application directory (assuming we're running from the backend-ai folder)
echo "📁 Copying application files..."
cp -r . /opt/napasa-ai-backend/
cd /opt/napasa-ai-backend

# Install dependencies
echo "📦 Installing Node.js dependencies..."
npm install --production

# Setup Python virtual environment for ML service
echo "🐍 Setting up Python ML service..."
cd ml_service
python3 -m venv venv
source venv/bin/activate
pip install --upgrade pip
pip install -r requirements.txt
deactivate
cd ..

# Copy environment file
echo "⚙️ Setting up environment..."
if [ ! -f ".env" ]; then
    cp env.example .env
    echo "✅ Environment file created from template"
    echo "⚠️ Please edit .env file with your actual values"
fi

# Create uploads and logs directories
echo "📁 Creating directories..."
mkdir -p uploads logs ml_service/logs
chmod 755 uploads logs ml_service/logs

# Setup PM2 ecosystem file for AI backend
echo "⚙️ Setting up PM2 configuration..."
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
      error_file: './logs/err.log',
      out_file: './logs/out.log',
      log_file: './logs/combined.log',
      time: true
    },
    {
      name: 'napasa-ml-service',
      script: 'ml_service/main.py',
      interpreter: 'ml_service/venv/bin/python',
      instances: 1,
      autorestart: true,
      watch: false,
      max_memory_restart: '2G',
      env: {
        NODE_ENV: 'production',
        PORT: 8000,
        HOST: '0.0.0.0'
      },
      error_file: './ml_service/logs/err.log',
      out_file: './ml_service/logs/out.log',
      log_file: './ml_service/logs/combined.log',
      time: true
    }
  ]
};
EOF

# Start the applications with PM2
echo "🚀 Starting applications with PM2..."
pm2 start ecosystem.config.js

# Save PM2 configuration
pm2 save

# Setup PM2 to start on boot
pm2 startup

# Configure Nginx for AI backend
echo "⚙️ Configuring Nginx for AI backend..."

# Add rate limiting zones to main nginx.conf
echo "⚙️ Adding rate limiting zones to main nginx.conf..."
sudo tee -a /etc/nginx/nginx.conf > /dev/null << 'EOF'

# Rate limiting zones for AI backend
limit_req_zone $binary_remote_addr zone=ai_api:10m rate=10r/s;
limit_req_zone $binary_remote_addr zone=ml_api:10m rate=5r/s;
EOF

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

    # AI Backend API routes
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

    # ML Service API routes
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

# Start PostgreSQL and Redis services
echo "🗄️ Starting database services..."
sudo systemctl start postgresql
sudo systemctl enable postgresql
sudo systemctl start redis-server
sudo systemctl enable redis-server

# Setup database
echo "🗄️ Setting up database..."
sudo -u postgres createdb ai_safari_db 2>/dev/null || echo "Database already exists"
sudo -u postgres psql -c "CREATE USER napasa_user WITH PASSWORD 'napasa_password';" 2>/dev/null || echo "User already exists"
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE ai_safari_db TO napasa_user;" 2>/dev/null || echo "Privileges already granted"

echo "✅ Deployment completed!"
echo "🌐 Your AI Backend is now available at:"
echo "   - AI Backend: http://13.51.162.253:3000"
echo "   - ML Service: http://13.51.162.253:8000"
echo "   - Via Nginx: http://13.51.162.253"
echo "🏥 Health checks:"
echo "   - AI Backend: http://13.51.162.253/ai/health"
echo "   - ML Service: http://13.51.162.253/ml/health"
echo "📡 API Base URLs:"
echo "   - AI API: http://13.51.162.253/ai/api"
echo "   - ML API: http://13.51.162.253/ml"
echo ""
echo "📋 Useful commands:"
echo "  pm2 status                    # Check application status"
echo "  pm2 logs napasa-ai-backend    # View AI backend logs"
echo "  pm2 logs napasa-ml-service    # View ML service logs"
echo "  pm2 restart napasa-ai-backend # Restart AI backend"
echo "  pm2 restart napasa-ml-service # Restart ML service"
echo "  sudo systemctl status nginx   # Check Nginx status"
echo "  sudo systemctl reload nginx   # Reload Nginx config"
echo "  sudo nginx -t                 # Test Nginx configuration"
echo ""
echo "⚠️ Don't forget to:"
echo "  1. Configure your EC2 security group to allow ports 80, 3000, and 8000"
echo "  2. Update your Flutter app to use the AI endpoints"
echo "  3. Edit .env file with your actual configuration"
echo "  4. Set up your database schema and seed data"
