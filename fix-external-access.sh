#!/bin/bash

echo "🔧 Fixing External Access Issues"
echo "==============================="

# Navigate to application directory
cd /opt/napasa-ai-backend

echo "1. Checking if services are running locally..."
echo "   Testing AI Backend (local)..."
if curl -s --connect-timeout 5 http://127.0.0.1:3000/health; then
    echo "   ✅ AI Backend local connection works"
else
    echo "   ❌ AI Backend local connection failed"
fi

echo "   Testing ML Service (local)..."
if curl -s --connect-timeout 5 http://127.0.0.1:8000/health; then
    echo "   ✅ ML Service local connection works"
else
    echo "   ❌ ML Service local connection failed"
fi

echo ""
echo "2. Checking Nginx status..."
sudo systemctl status nginx --no-pager -l

echo ""
echo "3. Checking if Nginx is listening on port 80..."
sudo netstat -tlnp | grep :80

echo ""
echo "4. Checking firewall status..."
sudo ufw status

echo ""
echo "5. Opening firewall ports..."
echo "   Opening port 80 (HTTP)..."
sudo ufw allow 80/tcp

echo "   Opening port 3000 (AI Backend)..."
sudo ufw allow 3000/tcp

echo "   Opening port 8000 (ML Service)..."
sudo ufw allow 8000/tcp

echo "   Enabling firewall..."
sudo ufw --force enable

echo ""
echo "6. Checking firewall status after changes..."
sudo ufw status

echo ""
echo "7. Checking if services are bound to all interfaces..."
echo "   Checking AI Backend binding..."
sudo netstat -tlnp | grep :3000

echo "   Checking ML Service binding..."
sudo netstat -tlnp | grep :8000

echo ""
echo "8. Testing external access again..."

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
echo "9. Checking EC2 security groups..."
echo "   Note: You need to check your EC2 security groups in AWS Console"
echo "   Make sure these ports are open:"
echo "   - Port 80 (HTTP) - Source: 0.0.0.0/0"
echo "   - Port 3000 (AI Backend) - Source: 0.0.0.0/0"
echo "   - Port 8000 (ML Service) - Source: 0.0.0.0/0"

echo ""
echo "10. Testing with different methods..."

echo "   Testing with wget..."
if wget -q --timeout=10 -O - http://13.51.162.253/ai/health; then
    echo "   ✅ AI Backend accessible via wget"
else
    echo "   ❌ AI Backend not accessible via wget"
fi

echo ""
echo "11. Checking if services are listening on all interfaces..."
echo "   AI Backend should be listening on 0.0.0.0:3000"
echo "   ML Service should be listening on 0.0.0.0:8000"

# Check PM2 configuration
echo ""
echo "12. Checking PM2 configuration..."
pm2 show napasa-ai-backend
pm2 show napasa-ml-service

echo ""
echo "13. Restarting services to ensure they bind to all interfaces..."
pm2 restart napasa-ai-backend
pm2 restart napasa-ml-service

echo "   Waiting for services to restart..."
sleep 10

echo ""
echo "14. Final test..."

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
echo "🎉 External access fix completed!"
echo ""
echo "📋 If external access still fails, check:"
echo "   1. EC2 Security Groups in AWS Console"
echo "   2. Make sure ports 80, 3000, 8000 are open"
echo "   3. Source should be 0.0.0.0/0 for all ports"
echo ""
echo "📋 Your AI Backend endpoints:"
echo "   🌐 AI Backend: http://13.51.162.253/ai/health"
echo "   🌐 ML Service: http://13.51.162.253/ml/health"
echo "   🌐 Direct AI:  http://13.51.162.253:3000/health"
echo "   🌐 Direct ML:  http://13.51.162.253:8000/health"



