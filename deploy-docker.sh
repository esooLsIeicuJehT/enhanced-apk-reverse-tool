#!/bin/bash

# Docker Deployment Script for Enhanced APK Reverse Engineering Tool
# This script builds and deploys all Docker containers

set -e

VERSION="2.0.0"
DOCKER_REGISTRY="esooLsIeicuJehT"
REGISTRY_URL="docker.io/$DOCKER_REGISTRY"

echo "=== Enhanced APK Reverse Engineering Tool - Docker Deployment ==="
echo "Version: $VERSION"
echo ""

# Color codes
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo "ERROR: Docker not installed. Please install Docker first."
    exit 1
fi

echo -e "${GREEN}✓${NC} Docker found: $(docker --version)"

# Login to Docker Hub
echo ""
echo "=== Logging into Docker Hub ==="
echo "Please enter your Docker Hub credentials:"
docker login

# Build main tool Dockerfile
echo ""
echo "=== Building Main Tool Docker Image ==="
echo "Building: Dockerfile.main-tool"
docker build -f Dockerfile.main-tool -t ${REGISTRY_URL}/apk-reverse-tool:${VERSION} -t ${REGISTRY_URL}/apk-reverse-tool:latest .
echo -e "${GREEN}✓${NC} Main tool built successfully"

# Build web interface
echo ""
echo "=== Building Web Interface Docker Image ==="
echo "Building: web-interface/Dockerfile"
cd web-interface
docker build -f Dockerfile -t ${REGISTRY_URL}/apk-web-interface:${VERSION} -t ${REGISTRY_URL}/apk-web-interface:latest .
cd ..
echo -e "${GREEN}✓${NC} Web interface built successfully"

# Tag for Docker Hub
echo ""
echo "=== Tagging Images for Docker Hub ==="
docker tag ${REGISTRY_URL}/apk-reverse-tool:${VERSION} ${DOCKER_REGISTRY}/apk-reverse-tool:${VERSION}
docker tag ${REGISTRY_URL}/apk-reverse-tool:latest ${DOCKER_REGISTRY}/apk-reverse-tool:latest
docker tag ${REGISTRY_URL}/apk-web-interface:${VERSION} ${DOCKER_REGISTRY}/apk-web-interface:${VERSION}
docker tag ${REGISTRY}/apk-web-interface:latest ${DOCKER}/apk-web-interface:latest
echo -e "${GREEN}✓${NC} Images tagged"

# Push to Docker Hub
echo ""
echo "=== Pushing Images to Docker Hub ==="
docker push ${DOCKER_REGISTRY}/apk-reverse-tool:${VERSION}
docker push ${DOCKER_REGISTRY}/apk-reverse-tool:latest
echo -e "${GREEN}✓${NC} Main tool pushed"
docker push ${DOCKER_REGISTRY}/apk-web-interface:${VERSION}
docker push ${DOCKER_REGISTRY}/apk-web-interface:latest
echo -e "${GREEN}✓${NC} Web interface pushed"

# Verify deployment
echo ""
echo "=== Verifying Deployment ==="
echo "Checking: main tool:latest"
docker pull ${DOCKER_REGISTRY}/apk-reverse-tool:latest
echo -e "${GREEN}✓${NC} Main tool verified"
echo "Checking: web:latest"
docker pull ${DOCKER_REGISTRY}/apk-web-interface:latest
echo -e "${GREEN}✓${NC} Web interface:verified"

echo ""
echo "=== Deployment Summary ==="
echo "Docker Hub Repository:"
echo "  Main Tool: https://hub.docker.com/r/${DOCKER_REGISTRY}/apk-reverse-tool"
echo "  Web Interface: https://hub.docker.com/r/${DOCKER_REGISTRY}/apk-web-interface"
echo ""
echo "Images:"
echo "  ${DOCKER_REGISTRY}/apk-reverse-tool:${VERSION}"
echo "  ${DOCKER_REGISTRY}/apk-reverse-tool:latest"
echo "  ${DOCKER_REGISTRY}/apk-web-interface:${VERSION}"
echo "  ${DOCKER_REGISTRY}/apk-web-interface:latest"
echo ""
echo -e "${GREEN}✓${NC} Docker deployment complete!"
echo ""
echo "Next Steps:"
echo "1. Test with: docker-compose up -d"
echo "2. Access API at: http://localhost:8080"
echo "3. Access Web UI: http://localhost:3000"