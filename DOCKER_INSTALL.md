# Docker Installation Guide for Aruba IoT Telemetry

This guide provides instructions for deploying the Aruba IoT Telemetry application using Docker.

## Prerequisites

- Docker installed on your system
  - [Install Docker for macOS](https://docs.docker.com/desktop/install/mac-install/)
  - [Install Docker for Linux](https://docs.docker.com/engine/install/)
- Git installed
  - [Install Git](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git)

## Git Setup Steps

### 1. Clone the repository
```bash
# Clone the repository
git clone https://github.com/kzmp/iot-aruba-telemetry.git

# Navigate to the project directory
cd iot-aruba-telemetry
```

### 2. Switch to a specific branch (if needed)
```bash
# List all available branches
git branch -a

# Switch to a specific branch
git checkout main
```

### 3. Pull the latest changes (if updating an existing clone)
```bash
# Update your local repository
git pull origin main
```

## Option 1: Using Docker Compose (Recommended)

### 1. Using the Quick Start Script

We provide a convenient script that handles the entire deployment process:

```bash
# Make the script executable
chmod +x start-docker.sh

# Run the script
./start-docker.sh
```

This script will:
- Check for Docker and Docker Compose
- Pull the latest code
- Build and start the containers
- Show container status
- Display access URLs

### 2. Manual Steps

#### a. Customize environment variables (Optional)
Edit the `docker-compose.yml` file to change any configuration options:
```yaml
environment:
  - ARUBA_AUTH_TOKENS=your-secure-token-1,your-secure-token-2
  - SECRET_KEY=your-unique-secret-key
```

### 3. Build and start the container
```bash
docker-compose up -d
```

This builds the Docker image and starts the container in detached mode.

### 4. Check the container status
```bash
docker-compose ps
```

### 5. View logs
```bash
docker-compose logs -f
```

### 6. Stop the container
```bash
docker-compose down
```

## Option 2: Using Docker CLI

If you prefer to use Docker commands directly:

### 1. Build the Docker image
```bash
docker build -t aruba-iot .
```

### 2. Run the container
```bash
docker run -d \
  --name aruba-iot \
  -p 9090:9090 \
  -p 9191:9191 \
  -e ARUBA_AUTH_TOKENS=1234,admin,aruba-iot \
  -e SECRET_KEY=your-unique-secret-key \
  aruba-iot
```

### 3. Check container status
```bash
docker ps
```

### 4. View logs
```bash
docker logs -f aruba-iot
```

### 5. Stop the container
```bash
docker stop aruba-iot
```

### 6. Remove the container
```bash
docker rm aruba-iot
```

## Accessing the Application

After starting the container, you can access:

- Web Dashboard: `http://localhost:9090`
- WebSocket Server: `ws://localhost:9191/aruba?token=YOUR_TOKEN`

## Using with Aruba Access Points

Configure your Aruba access points to connect to:
```
ws://YOUR_SERVER_IP:9191/aruba?token=TOKEN
```

Where:
- `YOUR_SERVER_IP` is the IP address of your Docker host
- `TOKEN` is one of the tokens configured in ARUBA_AUTH_TOKENS

## Persisting Data (Advanced)

For production use, you might want to persist data outside the container:

```bash
docker run -d \
  --name aruba-iot \
  -p 9090:9090 \
  -p 9191:9191 \
  -e ARUBA_AUTH_TOKENS=your-secure-token \
  -v /path/on/host/logs:/app/logs \
  -v /path/on/host/data:/app/data \
  aruba-iot
```

## Troubleshooting

### Container exits immediately
Check logs:
```bash
docker logs aruba-iot
```

### Can't connect to WebSocket
Ensure:
1. Ports are correctly mapped
2. Firewall allows connections to port 9191
3. You're using the correct token in the URL

### Dashboard not showing data
1. Check the WebSocket connection
2. Verify Aruba AP is sending data to the correct endpoint
3. Check logs for any error messages

## Security Considerations

1. Change default tokens in production
2. Consider placing behind a reverse proxy with SSL
3. Use a secure SECRET_KEY
4. Restrict access to the Docker host
