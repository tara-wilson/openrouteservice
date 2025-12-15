#!/bin/bash
# Setup script for OpenRouteService on Hetzner server for US coverage
# This script automates the setup process

set -e

echo "=========================================="
echo "OpenRouteService US Setup for Hetzner"
echo "=========================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if running as root
if [ "$EUID" -eq 0 ]; then 
   echo -e "${RED}Please do not run this script as root${NC}"
   exit 1
fi

# Check Docker installation
if ! command -v docker &> /dev/null; then
    echo -e "${YELLOW}Docker is not installed. Installing Docker...${NC}"
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh
    sudo usermod -aG docker $USER
    rm get-docker.sh
    echo -e "${GREEN}Docker installed. Please log out and log back in, then run this script again.${NC}"
    exit 0
fi

# Check Docker permissions
if ! docker ps &> /dev/null; then
    echo -e "${YELLOW}Docker is installed but you don't have permission to access it.${NC}"
    if groups | grep -q docker; then
        echo -e "${YELLOW}You are in the docker group, but need to activate it.${NC}"
        echo -e "${YELLOW}Run: newgrp docker${NC}"
        echo -e "${YELLOW}Or log out and log back in, then run this script again.${NC}"
    else
        echo -e "${YELLOW}Adding you to the docker group...${NC}"
        sudo usermod -aG docker $USER
        echo -e "${GREEN}Added to docker group. Please run: newgrp docker${NC}"
        echo -e "${YELLOW}Or log out and log back in, then run this script again.${NC}"
    fi
    exit 1
fi

# Check Docker Compose installation
if ! command -v docker compose &> /dev/null; then
    echo -e "${YELLOW}Docker Compose is not installed. Installing...${NC}"
    sudo apt-get update
    sudo apt-get install -y docker-compose-plugin
fi

# Create necessary directories
echo -e "${GREEN}Creating directories...${NC}"
mkdir -p ors-docker/{config,files,graphs,elevation_cache,logs}
chmod -R 755 ors-docker

# Copy configuration file
if [ ! -f "ors-docker/config/ors-config.yml" ]; then
    echo -e "${GREEN}Copying US configuration file...${NC}"
    cp ors-config.us.yml ors-docker/config/ors-config.yml
    echo -e "${GREEN}Configuration file copied.${NC}"
else
    echo -e "${YELLOW}Configuration file already exists. Skipping...${NC}"
fi

# Check if US OSM PBF file exists
US_PBF_FILE="ors-docker/files/us-latest.osm.pbf"
if [ ! -f "$US_PBF_FILE" ]; then
    echo -e "${YELLOW}US OSM PBF file not found.${NC}"
    echo -e "${YELLOW}You need to download the US OSM file from Geofabrik.${NC}"
    echo ""
    echo "Download options:"
    echo "1. Full US (recommended): ~5-10GB"
    echo "   wget -O $US_PBF_FILE https://download.geofabrik.de/north-america/us-latest.osm.pbf"
    echo ""
    echo "2. Individual states (smaller, faster to build):"
    echo "   Example for California:"
    echo "   wget -O ors-docker/files/california-latest.osm.pbf https://download.geofabrik.de/north-america/us/california-latest.osm.pbf"
    echo ""
    read -p "Do you want to download the full US file now? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${GREEN}Downloading US OSM PBF file (this may take a while)...${NC}"
        wget -O "$US_PBF_FILE" https://download.geofabrik.de/north-america/us-latest.osm.pbf
        echo -e "${GREEN}Download complete!${NC}"
    else
        echo -e "${YELLOW}Please download the OSM file manually before starting the container.${NC}"
        echo -e "${YELLOW}Update ors-config.us.yml with the correct file path if using a different file.${NC}"
    fi
else
    echo -e "${GREEN}US OSM PBF file found: $US_PBF_FILE${NC}"
fi

# Check system memory
TOTAL_MEM=$(free -g | awk '/^Mem:/{print $2}')
echo ""
echo -e "${GREEN}System Information:${NC}"
echo "Total RAM: ${TOTAL_MEM}GB"
echo ""

if [ "$TOTAL_MEM" -lt 32 ]; then
    echo -e "${RED}WARNING: You have less than 32GB RAM.${NC}"
    echo -e "${RED}For the full US dataset, we recommend at least 32GB RAM.${NC}"
    echo -e "${YELLOW}Consider using a smaller region or upgrading your server.${NC}"
    echo ""
    read -p "Continue anyway? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Update vm.max_map_count for large builds
CURRENT_MAX_MAP=$(sysctl vm.max_map_count | awk '{print $3}')
if [ "$CURRENT_MAX_MAP" -lt 81920 ]; then
    echo -e "${YELLOW}Updating vm.max_map_count for large builds...${NC}"
    echo "vm.max_map_count=81920" | sudo tee -a /etc/sysctl.conf
    sudo sysctl -p
    echo -e "${GREEN}vm.max_map_count updated to 81920${NC}"
else
    echo -e "${GREEN}vm.max_map_count is already set to $CURRENT_MAX_MAP (OK)${NC}"
fi

# Build Docker image
echo ""
echo -e "${GREEN}Building Docker image (this may take several minutes)...${NC}"
docker compose -f docker-compose.us.yml build

echo ""
echo -e "${GREEN}=========================================="
echo "Setup Complete!"
echo "==========================================${NC}"
echo ""
echo "Next steps:"
echo "1. Review the configuration in ors-docker/config/ors-config.yml"
echo "2. Adjust memory settings in docker-compose.us.yml if needed"
echo "3. Start the service:"
echo "   docker compose -f docker-compose.us.yml up -d"
echo ""
echo "4. Monitor the logs (graph building takes time):"
echo "   docker compose -f docker-compose.us.yml logs -f"
echo ""
echo "5. Check health status:"
echo "   curl http://localhost:8080/ors/v2/health"
echo ""
echo "6. Once ready, test routing:"
echo "   curl 'http://localhost:8080/ors/v2/directions/driving-car?start=-74.006,40.7128&end=-73.9352,40.7589'"
echo ""
echo "Note: Initial graph building for the US can take several hours."
echo "      The service will be available once graphs are built."

