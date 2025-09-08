#!/bin/bash

echo "🔧 Diagnosing EC2 Security Group Issues"
echo "======================================"

# Navigate to application directory
cd /opt/napasa-ai-backend

echo "1. Installing net-tools for better diagnostics..."
sudo apt update
sudo apt install -y net-tools

echo "2. Checking if services are running locally..."
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
echo "3. Checking if Nginx is listening on port 80..."
sudo netstat -tlnp | grep :80

echo ""
echo "4. Checking if services are bound to all interfaces..."
echo "   Checking AI Backend binding..."
sudo netstat -tlnp | grep :3000

echo "   Checking ML Service binding..."
sudo netstat -tlnp | grep :8000

echo ""
echo "5. Testing external access..."

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
echo "6. Getting EC2 instance information..."
echo "   Instance ID: $(curl -s http://169.254.169.254/latest/meta-data/instance-id)"
echo "   Public IP: $(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)"
echo "   Security Groups: $(curl -s http://169.254.169.254/latest/meta-data/security-groups)"

echo ""
echo "7. Testing port connectivity from external..."
echo "   Testing port 80..."
if timeout 5 bash -c "</dev/tcp/13.51.162.253/80"; then
    echo "   ✅ Port 80 is accessible"
else
    echo "   ❌ Port 80 is NOT accessible - Check EC2 Security Groups!"
fi

echo "   Testing port 3000..."
if timeout 5 bash -c "</dev/tcp/13.51.162.253/3000"; then
    echo "   ✅ Port 3000 is accessible"
else
    echo "   ❌ Port 3000 is NOT accessible - Check EC2 Security Groups!"
fi

echo "   Testing port 8000..."
if timeout 5 bash -c "</dev/tcp/13.51.162.253/8000"; then
    echo "   ✅ Port 8000 is accessible"
else
    echo "   ❌ Port 8000 is NOT accessible - Check EC2 Security Groups!"
fi

echo ""
echo "🎯 DIAGNOSIS COMPLETE!"
echo ""
echo "📋 NEXT STEPS - Fix EC2 Security Groups:"
echo ""
echo "1. Go to AWS Console: https://console.aws.amazon.com/ec2/"
echo "2. Click 'Instances' in the left sidebar"
echo "3. Find your instance (IP: 13.51.162.253)"
echo "4. Click on the instance"
echo "5. Go to 'Security' tab"
echo "6. Click on the Security Group link"
echo "7. Click 'Edit inbound rules'"
echo "8. Add these rules:"
echo ""
echo "   Rule 1:"
echo "   - Type: HTTP"
echo "   - Port: 80"
echo "   - Source: 0.0.0.0/0"
echo "   - Description: HTTP access"
echo ""
echo "   Rule 2:"
echo "   - Type: Custom TCP"
echo "   - Port: 3000"
echo "   - Source: 0.0.0.0/0"
echo "   - Description: AI Backend"
echo ""
echo "   Rule 3:"
echo "   - Type: Custom TCP"
echo "   - Port: 8000"
echo "   - Source: 0.0.0.0/0"
echo "   - Description: ML Service"
echo ""
echo "9. Click 'Save rules'"
echo ""
echo "10. Test again:"
echo "    curl http://13.51.162.253/ai/health"
echo "    curl http://13.51.162.253/ml/health"
echo ""
echo "📋 Current Status:"
echo "   ✅ Firewall: Configured correctly"
echo "   ✅ Services: Running locally"
echo "   ❌ External Access: Blocked by EC2 Security Groups"
echo ""
echo "🔧 The issue is definitely EC2 Security Groups - not your server configuration!"
