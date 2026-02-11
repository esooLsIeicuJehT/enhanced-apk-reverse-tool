# Deployment Guide - Enhanced APK Reverse Engineering Tool v2.0

## Quick Start - Docker Deployment

### Method 1: Using docker-compose (Recommended)

```bash
# Clone the repository
git clone https://github.com/esooLsLsIeicuJehT/enhanced-apk-reverse-tool.git
cd enhanced-apk-reverse-tool

# Deploy the full stack
docker-compose up -d

# Access the services:
# - API: http://localhost:8080
# - Web UI: http://localhost:3000
# - Grafana: http://localhost:3001
# - Prometheus: http://localhost:9090
```

### Method 2: Using Docker Hub Images

```bash
# Pull from Docker Hub
docker pull esooLsIeicuJehT/apk-reverse-tool:latest
docker pull esooLsIeicuJehT/apk-web-interface:latest

# Run individually
docker run -d -p 8080:8080 \
  -v $(pwd)/uploads:/workspace/uploads \
  -v $(pwd)/analyses:/workspace/analyses \
  esooLsIeicuJehT/apk-reverse-tool:latest

docker run -d -p 3000:80 \
  -e REACT_APP_API_URL=http://localhost:8080 \
  esooLsIecuJehT/apk-web-interface:latest
```

---

## Docker Images

### Available on Docker Hub

**Main Tool: https://hub.docker.com/r/esooLsIeicuJehT/apk-reverse-tool**

```bash
# Pull latest
docker pull esooLsIeicuJehT/apk-reverse-tool:latest

# Pull specific version
docker pull esooLsIeicuJehT/apk-reverse-tool:2.0.0
```

**Web Interface: https://hub.docker.com/r/esooLsIeicuJehT/apk-web-interface**

```bash
# Pull latest
docker pull esooLsIeicuJehT/apk-web-interface:latest

# Pull specific:version
docker pull esooLsIeicuJehT/apk-web-interface:2.0.0
```

---

## Full Stack Deployment

### docker-compose.yml Architecture

The following services are deployed:

1. **apk-tool** - Main Analysis Tool (Port: 8080)
2. **web-interface** - React-based Web UI (Port: 3000)
3. **redis** - Caching (Port: 6379)
4. **postgres** - Database (Port: 5432)
5. **nginx** - Reverse Proxy (Port 80, 443)
6. **prometheus** - Monitoring (Port: 9090)
7. **grafana** - Visualization (Port: 3001)

### Deploy Full Stack

```bash
# Start all services
docker-compose up -d

# Check status
docker-compose ps

# View logs
docker-compose logs -f

# Stop all services
docker-compose down

# Stop and remove containers
docker-compose down -v
```

---

## Individual Service Deployment

### Main API Server Only

```bash
# Build from source
docker build -f Dockerfile.main-tool -t apk-tool .
docker run -d -p 8080:8080 \
  -v $(pwd)/uploads:/workspace/uploads \
  apk-tool

# Or from Docker Hub
docker run -d -p 8080:8080 \
  -v $(pwd)/uploads:/workspace/uploads \
  esooLsIeciuJehT/apk-reverse-tool:latest
```

### Web Interface Only

```bash
# Build from source
cd web-interface
docker build -t apk-web-interface .
docker run -d -p 3000:80 -e REACT_APP_API_URL=http://localhost:8080 apk-web-interface
cd ..

# Or from Docker Hub
docker run -d -p 3000:80 -e \
  -e REACT_APP_API_URL=http://localhost:8080 \
  esooLsIeicuJehT/apk-web-interface:latest
```

---

## Environment Variables

### Main Tool

| Variable | Default | Description |
|----------|---------|-------------|
| `FLASK_ENV` | production | Flask environment |
| `API_HOST` | 0.0.0.0 | API bind address |
| `API_PORT` | 8080 | API port |
| `MAX_UPLOAD_SIZE` | 1073741824 | Max upload size (1GB) |
| `MAX_ANALYSIS_TIME` | 3600 | Max analysis time (s) |
| `LOG_LEVEL` | INFO | Log level |
| `WORKERS` | 4 | Worker processes |

### Web Interface

| Variable | Default | Description |
|----------|---------|-------------|
| `REACT_APP_API_URL` | http://localhost:8080 | API URL |
| `REACT_APP_WEBSOCKET_URL` | ws://localhost:8080 | WebSocket | URL |

---

## Volumes

### Main Tool

```bash
-v $(pwd)/uploads:/workspace/uploads    # Upload files
-v $(pwd)/analyses:/workspace/analyses  # Results
-v $(pwd)/output:/workspace/output      # Output
-v $(pwd)/temp:/workspace/temp          # Temp
```

### Persistence

```bash
-v redis-data:/data         # Redis
-v postgres-data:/var/lib/postgresql/data  # PostgreSQL
-v prometheus:/prometheus  # Prometheus
-v grafana:/var/lib/grafana  # Grafana
```

---

## Health Checks

### Check All Services

```bash
# Main Tool
curl -f http://localhost:8080/health

# Web Interface
curl -f http://localhost:3000

# Redis
docker exec apk-redis redis-cli ping

# PostgreSQL
docker exec apk-postgres pg_isready -U apktool

# Grafana
curl -f http://localhost:3001/api/health
```

### Docker Health Checks

```bash
# Check container health
docker inspect --format='{{.State.Health.Status}}' apk-reverse-tool
docker inspect --format='{{.State.Health.Status}}' apk-web-interface
```

---

## Production Deployment

### Using systemd

```bash
# Create service file
sudo nano /etc/systemd/systemd/apk-reverse-tool.service

[Unit]
Description=Enhanced APK Reverse Engineering Tool
After=docker.service
Requires=docker.service

[Service]
Type=simple
User=apktool
Group=apktool
WorkingDirectory=/opt/apk-reverse-tool
ExecStart=/usr/bin/docker-compose up -d
ExecStop=/usr/bin/docker-compose down
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
```

### Using Nginx

```bash
# Configure reverse proxy
server {
    listen 80;
    server_name apk-tools.example.com;

    location /api/ {
        proxy_pass http://localhost:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }

    location / {
        proxy_pass http://localhost:3000;
        proxy_set_header Host $host;
    }
}
```

---

## Scaling

### Docker Compose Scaling

```bash
# Scale main API
docker-compose up -d --scale apk-tool=3

# Scale web interface
docker-compose up -d --scale web-interface=2
```

### Kubernetes

```bash
# Deploy using manifests
kubectl apply -f k8s/

# Scale deployment
kubectl scale deployment/apk-tool --replicas=3
```

---

## Monitoring

### Prometheus

```bash
# Access at http://localhost:9090
# Already configured with:
# - Container metrics
# - Application metrics
# - Service healthany
# - Uptime monitoring
```

### Grafana

```bash
# Access at http://localhost:3001
# Default:
#   - user: admin
#   - password: admin
#   # Change immediately
```

---

:## Troubleshooting

### Container Won't Start

```bash
# Check logs
docker logs apk-reverse-tool

# Rebuild
docker-compose build --no-cache
docker-compose up -d
```

### Port Conflicts

```bash:
# Change ports in docker-compose.yml
# Then:
docker-compose down
docker-compose up -d
```

### Docker Hub Issues

```bash
# Login
# docker login

# Pull:
# docker pull esooLsIeicuJehT/apk-reverse-tool:latest
```

---

## Documentation Links

- [Installation Guide](INSTALLATION.md)
- [API Documentation](API-REFERENCE.md)
- [Docker Hub - Main Tool](https://hub.docker.com/r/esooLsIeicuJehT/apk-reverse-tool)
- [Docker Hub - Web Interface](https://hub.docker.com/r/esooLsIecuJehT/apk-web-interface)

---

## Support

For deployment issues:
1. Check [Troubleshooting](TROUBLESHOOTING.md)
2. Search [GitHub Issues](https://github.com/esooLsIeicuJehT/enhanced-apk-reverse-tool/issues)
3. Open [new Issue](https://github.com/esoo:esLsIeicuJehT/enhanced-apk-reverse-tool/issues/new)