#!/bin/bash
# Aruba IoT Telemetry Server - Quick Setup Script

set -e

echo "🚀 Aruba IoT Telemetry Server - Quick Setup"
echo "=========================================="

# Check Python version
echo "📋 Checking Python version..."
python3 --version || {
    echo "❌ Python 3 is required but not installed."
    exit 1
}

# Create virtual environment
echo "🔧 Creating Python virtual environment..."
python3 -m venv .venv

# Activate virtual environment
echo "🔧 Activating virtual environment..."
source .venv/bin/activate

# Install dependencies
echo "📦 Installing dependencies..."
pip install --upgrade pip
pip install -r requirements.txt

# Create .env file if it doesn't exist
if [ ! -f .env ]; then
    echo "⚙️ Creating environment configuration..."
    cat > .env << EOF
# Flask Configuration
FLASK_HOST=0.0.0.0
FLASK_PORT=9090
FLASK_DEBUG=False
SECRET_KEY=$(openssl rand -base64 32)

# Aruba WebSocket Server Configuration
ARUBA_WS_HOST=0.0.0.0
ARUBA_WS_PORT=9191

# Authentication Configuration - CHANGE THESE TOKENS!
ARUBA_AUTH_TOKENS=admin-$(date +%s),secure-token-$(openssl rand -hex 8),aruba-iot

# Logging Configuration
LOG_LEVEL=INFO
EOF
    echo "✅ Created .env file with random tokens"
else
    echo "✅ .env file already exists"
fi

# Test the installation
echo "🧪 Testing installation..."
python -c "import flask, flask_socketio, websockets; print('✅ All dependencies installed successfully')"

# Get IP addresses
echo ""
echo "🌐 Network Configuration:"
echo "========================="
if command -v ip &> /dev/null; then
    ip addr show | grep -E "inet [0-9]" | grep -v "127.0.0.1" | awk '{print "📍 " $2}' | head -3
elif command -v ifconfig &> /dev/null; then
    ifconfig | grep -E "inet [0-9]" | grep -v "127.0.0.1" | awk '{print "📍 " $2}' | head -3
else
    echo "📍 Unable to detect IP addresses automatically"
fi

echo ""
echo "✅ Setup Complete!"
echo "=================="
echo ""
echo "🚀 To start the server:"
echo "   source .venv/bin/activate"
echo "   python app.py"
echo ""
echo "🌐 Access URLs:"
echo "   Web Dashboard: http://YOUR_IP:9090"
echo "   WebSocket: ws://YOUR_IP:9191/aruba?token=YOUR_TOKEN"
echo ""
echo "🔐 Your authentication tokens are in the .env file"
echo "   IMPORTANT: Change the default tokens before production use!"
echo ""
echo "📖 For detailed deployment guide, see: DEPLOYMENT_GUIDE.md"
