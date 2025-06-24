#!/bin/bash
# Quick start script for Aruba IoT Telemetry Docker deployment

# Echo commands as they execute
set -x

# Stop on error
set -e

echo "🚀 Deploying Aruba IoT Telemetry Server with Docker"
echo "======================================================"

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo "❌ Docker is not installed. Please install Docker first."
    exit 1
fi

# Check if Docker Compose is installed
if ! command -v docker-compose &> /dev/null; then
    echo "❌ Docker Compose is not installed. Please install Docker Compose first."
    exit 1
fi

# Pull latest changes
echo "🔄 Pulling latest changes..."
git pull origin main

# Build and start containers
echo "🐳 Building and starting Docker containers..."
docker-compose up -d

# Check if containers are running
echo "✅ Checking container status..."
docker-compose ps

# Get the IP address
IP_ADDRESS=$(hostname -I | awk '{print $1}')

echo "======================================================"
echo "✅ Deployment completed successfully!"
echo "📊 Dashboard URL: http://$IP_ADDRESS:9090"
echo "🔌 WebSocket URL: ws://$IP_ADDRESS:9191/aruba?token=1234"
echo ""
echo "📝 View logs: docker-compose logs -f"
echo "🛑 Stop server: docker-compose down"
echo "======================================================"
