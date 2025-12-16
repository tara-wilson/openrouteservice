#!/bin/bash
# Setup script for running multiple ORS regions simultaneously
# California on port 8080, US Northeast on port 8081

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo "=========================================="
echo "Multi-Region ORS Setup"
echo "=========================================="
echo ""
echo "This will set up:"
echo "  - California on port 8080"
echo "  - US Northeast on port 8081"
echo ""
echo -e "${YELLOW}Note: Both instances will run simultaneously${NC}"
echo -e "${YELLOW}Memory: Each instance uses ~20GB, total ~40GB needed${NC}"
echo -e "${RED}WARNING: Your server has 32GB RAM - this may not work!${NC}"
echo ""
read -p "Continue anyway? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    exit 1
fi

# Step 1: Create separate graph directories
echo ""
echo -e "${GREEN}Step 1: Creating graph directories...${NC}"
mkdir -p ors-docker/graphs/california
mkdir -p ors-docker/graphs/northeast
echo -e "${GREEN}✓ Directories created${NC}"

# Step 2: Copy config files
echo ""
echo -e "${GREEN}Step 2: Setting up configuration files...${NC}"
if [ ! -f "ors-docker/config/ors-config-california.yml" ]; then
    cp ors-config-california.yml ors-docker/config/ors-config-california.yml
    echo -e "${GREEN}✓ California config created${NC}"
else
    echo -e "${YELLOW}California config already exists${NC}"
fi

if [ ! -f "ors-docker/config/ors-config-northeast.yml" ]; then
    cp ors-config-northeast.yml ors-docker/config/ors-config-northeast.yml
    echo -e "${GREEN}✓ Northeast config created${NC}"
else
    echo -e "${YELLOW}Northeast config already exists${NC}"
fi

# Step 3: Check OSM files
echo ""
echo -e "${GREEN}Step 3: Checking OSM files...${NC}"
CALIFORNIA_FILE="ors-docker/files/california-latest.osm.pbf"
NORTHEAST_FILE="ors-docker/files/us-northeast-latest.osm.pbf"

if [ ! -f "$CALIFORNIA_FILE" ]; then
    echo -e "${YELLOW}⚠ California file not found: $CALIFORNIA_FILE${NC}"
    echo "Download it with: wget -O $CALIFORNIA_FILE https://download.geofabrik.de/north-america/us/california-latest.osm.pbf"
else
    echo -e "${GREEN}✓ California file found${NC}"
fi

if [ ! -f "$NORTHEAST_FILE" ]; then
    echo -e "${YELLOW}⚠ Northeast file not found: $NORTHEAST_FILE${NC}"
    echo "Download it with: wget -O $NORTHEAST_FILE https://download.geofabrik.de/north-america/us-northeast-latest.osm.pbf"
else
    echo -e "${GREEN}✓ Northeast file found${NC}"
fi

# Step 4: Summary
echo ""
echo -e "${GREEN}=========================================="
echo "Setup Complete!"
echo "==========================================${NC}"
echo ""
echo "Next steps:"
echo ""
echo "1. Build graphs for California (if not already built):"
echo "   Edit docker-compose.california.yml: REBUILD_GRAPHS: True"
echo "   docker compose -f docker-compose.california.yml up -d"
echo ""
echo "2. Build graphs for Northeast (if not already built):"
echo "   Edit docker-compose.northeast.yml: REBUILD_GRAPHS: True"
echo "   docker compose -f docker-compose.northeast.yml up -d"
echo ""
echo "3. Start both instances:"
echo "   docker compose -f docker-compose.california.yml up -d"
echo "   docker compose -f docker-compose.northeast.yml up -d"
echo ""
echo "4. Test:"
echo "   California: curl 'http://localhost:8080/ors/v2/health'"
echo "   Northeast:  curl 'http://localhost:8081/ors/v2/health'"
echo ""
echo -e "${RED}IMPORTANT: With 32GB RAM, running both simultaneously may cause OOM errors.${NC}"
echo -e "${YELLOW}Consider building graphs separately, then running both with REBUILD_GRAPHS: False${NC}"

