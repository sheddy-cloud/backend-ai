# NAPASA AI Backend EC2 Deployment Guide

## 🚀 Quick Deployment Steps

### 1. Prepare Your EC2 Instance

```bash
# Connect to your EC2 instance
ssh -i your-key.pem ubuntu@13.51.162.253

# Update system
sudo apt update && sudo apt upgrade -y
```

### 2. Upload Your Code

**Option A: Using Git (Recommended)**
```bash
# Clone your repository
git clone https://github.com/yourusername/napasa-ai-backend.git
cd napasa-ai-backend
```

**Option B: Using SCP**
```bash
# From your local machine
scp -i your-key.pem -r backend-ai/ ubuntu@13.51.162.253:/home/ubuntu/
```

### 3. Run the Deployment Script

```bash
# Make the script executable
chmod +x deploy-ec2.sh

# Run the deployment script
./deploy-ec2.sh
```

### 4. Configure Environment

```bash
# Edit the environment file
nano .env

# Make sure these values are correct:
# DB_HOST=localhost
# DB_NAME=ai_safari_db
# DB_USER=napasa_user
# DB_PASSWORD=napasa_password
# REDIS_HOST=localhost
# REDIS_PORT=6379
```

### 5. Start the Applications

```bash
# Start with PM2
pm2 start ecosystem.config.js

# Check status
pm2 status

# View logs
pm2 logs
```

## 🔧 EC2 Security Group Configuration

Make sure your EC2 security group allows:

| Type | Protocol | Port Range | Source |
|------|----------|------------|---------|
| HTTP | TCP | 80 | 0.0.0.0/0 |
| HTTP | TCP | 3000 | 0.0.0.0/0 |
| HTTP | TCP | 8000 | 0.0.0.0/0 |
| PostgreSQL | TCP | 5432 | 0.0.0.0/0 |
| Redis | TCP | 6379 | 0.0.0.0/0 |
| SSH | TCP | 22 | Your IP |

## 📱 Update Flutter App

Your Flutter app can now use the AI endpoints:

```dart
// AI Backend endpoints
static const String aiBaseUrl = 'http://13.51.162.253/ai/api';
static const String mlBaseUrl = 'http://13.51.162.253/ml';
```

## 🏥 Health Check

Test your deployment:
```bash
# AI Backend health check
curl http://13.51.162.253/ai/health

# ML Service health check
curl http://13.51.162.253/ml/health

# Direct access
curl http://13.51.162.253:3000/health
curl http://13.51.162.253:8000/health
```

Expected responses:
```json
{
  "status": "OK",
  "message": "AI Safari Backend is running! 🦁",
  "timestamp": "2024-01-01T00:00:00.000Z",
  "version": "1.0.0"
}
```

## 📋 Useful Commands

```bash
# PM2 Commands
pm2 status                    # Check application status
pm2 logs napasa-ai-backend    # View AI backend logs
pm2 logs napasa-ml-service    # View ML service logs
pm2 restart napasa-ai-backend # Restart AI backend
pm2 restart napasa-ml-service # Restart ML service
pm2 monit                     # Monitor resources

# Nginx Commands
sudo systemctl status nginx   # Check Nginx status
sudo systemctl reload nginx   # Reload Nginx configuration
sudo systemctl restart nginx  # Restart Nginx
sudo nginx -t                 # Test Nginx configuration

# Database Commands
sudo systemctl status postgresql  # Check PostgreSQL status
sudo -u postgres psql ai_safari_db  # Connect to database
sudo systemctl status redis-server  # Check Redis status
redis-cli ping  # Test Redis connection
```

## 🔍 Troubleshooting

### AI Backend won't start
```bash
# Check logs
pm2 logs napasa-ai-backend

# Check if port is in use
sudo netstat -tlnp | grep :3000

# Check environment
cat .env
```

### ML Service won't start
```bash
# Check logs
pm2 logs napasa-ml-service

# Check Python environment
cd ml_service
source venv/bin/activate
python main.py

# Check dependencies
pip list
```

### Database connection issues
```bash
# Check PostgreSQL status
sudo systemctl status postgresql

# Check database exists
sudo -u postgres psql -l

# Check user permissions
sudo -u postgres psql -c "\du"
```

### Nginx issues
```bash
# Test configuration
sudo nginx -t

# Check error logs
sudo tail -f /var/log/nginx/error.log

# Check access logs
sudo tail -f /var/log/nginx/access.log
```

## 🌐 Your API Endpoints

Once deployed, your AI APIs will be available at:

### Via Nginx (Recommended)
- **AI Backend**: `http://13.51.162.253/ai/api`
- **ML Service**: `http://13.51.162.253/ml`
- **Health Checks**: 
  - `http://13.51.162.253/ai/health`
  - `http://13.51.162.253/ml/health`

### Direct Access (For Debugging)
- **AI Backend**: `http://13.51.162.253:3000`
- **ML Service**: `http://13.51.162.253:8000`
- **Health Checks**:
  - `http://13.51.162.253:3000/health`
  - `http://13.51.162.253:8000/health`

### API Routes
- **Wildlife**: `GET http://13.51.162.253/ai/api/wildlife`
- **Routes**: `GET http://13.51.162.253/ai/api/routes`
- **Accommodations**: `GET http://13.51.162.253/ai/api/accommodations`
- **Recommendations**: `GET http://13.51.162.253/ai/api/recommendations`
- **ML Predictions**: `POST http://13.51.162.253/ml/predict`

## 🔄 Updates and Maintenance

```bash
# Pull latest changes
git pull origin main

# Install new dependencies
npm install
cd ml_service && source venv/bin/activate && pip install -r requirements.txt

# Restart applications
pm2 restart napasa-ai-backend
pm2 restart napasa-ml-service
```

## 📊 Monitoring

PM2 provides built-in monitoring:
```bash
# Real-time monitoring
pm2 monit

# View detailed status
pm2 show napasa-ai-backend
pm2 show napasa-ml-service
```

## 🐳 Docker Alternative

If you prefer Docker deployment:
```bash
# Build and start with Docker Compose
docker-compose -f docker-compose.prod.yml up -d

# Check status
docker-compose -f docker-compose.prod.yml ps

# View logs
docker-compose -f docker-compose.prod.yml logs -f
```

Your NAPASA AI backend is now ready for production! 🎉



