#!/bin/bash
# Quick start script for Aruba IoT Telemetry Application

echo "🌐 Aruba IoT Telemetry Application - Quick Start"
echo "================================================"

# Check if virtual environment exists
if [ ! -d ".venv" ]; then
    echo "❌ Virtual environment not found. Please run the setup first."
    echo "   Run: python -m venv .venv && source .venv/bin/activate && pip install -r requirements.txt"
    exit 1
fi

# Activate virtual environment
source .venv/bin/activate

echo "✅ Virtual environment activated"

# Install dependencies if needed
echo "📦 Checking dependencies..."
pip install -r requirements.txt > /dev/null 2>&1

echo "🚀 Starting Aruba IoT Telemetry Server..."
echo ""
echo "📊 Dashboard will be available at: http://localhost:9090"
echo "🔌 WebSocket server for Aruba APs: ws://localhost:9191"
echo ""
echo "💡 To test with simulator, run in another terminal:"
echo "   source .venv/bin/activate && python test_client.py"
echo ""
echo "🛑 Press Ctrl+C to stop the server"
echo ""

# Start the application
python app.py
