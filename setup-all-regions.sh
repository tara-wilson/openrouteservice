#!/bin/bash
# Setup script for all US regions as multi-region instances
# Each region runs on a different port

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

echo "=========================================="
echo "Multi-Region ORS Setup - All US Regions"
echo "=========================================="
echo ""
echo "This will set up 5 US regions:"
echo "  ${BLUE}1. US Pacific${NC}      (port 8080) - CA, OR, WA, NV, HI"
echo "  ${BLUE}2. US West${NC}        (port 8081) - AZ, CO, ID, MT, NM, UT, WY"
echo "  ${BLUE}3. US Northeast${NC}    (port 8082) - NY, PA, NJ, MA, CT, VT, NH, ME, RI"
echo "  ${BLUE}4. US South${NC}       (port 8083) - TX, FL, GA, NC, etc."
echo "  ${BLUE}5. US Midwest${NC}     (port 8084) - IL, OH, MI, IN, etc."
echo ""
echo -e "${RED}WARNING: Running all 5 regions simultaneously requires ~110GB RAM!${NC}"
echo -e "${YELLOW}Your server has 32GB RAM - you can only run 1-2 regions at a time.${NC}"
echo ""
echo "Recommended approach:"
echo "  1. Build graphs for all regions separately (one at a time)"
echo "  2. Run only the regions you need simultaneously"
echo ""
read -p "Continue with setup? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    exit 1
fi

# Step 1: Create graph directories
echo ""
echo -e "${GREEN}Step 1: Creating graph directories...${NC}"
for region in pacific west northeast south midwest; do
    mkdir -p "ors-docker/graphs/${region}"
done
echo -e "${GREEN}✓ Directories created${NC}"

# Step 2: Copy config files
echo ""
echo -e "${GREEN}Step 2: Setting up configuration files...${NC}"
for region in pacific west northeast south midwest; do
    if [ ! -f "ors-docker/config/ors-config-${region}.yml" ]; then
        cp "ors-config-${region}.yml" "ors-docker/config/ors-config-${region}.yml"
        echo -e "${GREEN}✓ ${region} config created${NC}"
    else
        echo -e "${YELLOW}${region} config already exists${NC}"
    fi
done

# Step 3: Check OSM files
echo ""
echo -e "${GREEN}Step 3: Checking OSM files...${NC}"
declare -A REGION_FILES=(
    ["pacific"]="us-pacific-latest.osm.pbf"
    ["west"]="us-west-latest.osm.pbf"
    ["northeast"]="us-northeast-latest.osm.pbf"
    ["south"]="us-south-latest.osm.pbf"
    ["midwest"]="us-midwest-latest.osm.pbf"
)

declare -A REGION_URLS=(
    ["pacific"]="https://download.geofabrik.de/north-america/us-pacific-latest.osm.pbf"
    ["west"]="https://download.geofabrik.de/north-america/us-west-latest.osm.pbf"
    ["northeast"]="https://download.geofabrik.de/north-america/us-northeast-latest.osm.pbf"
    ["south"]="https://download.geofabrik.de/north-america/us-south-latest.osm.pbf"
    ["midwest"]="https://download.geofabrik.de/north-america/us-midwest-latest.osm.pbf"
)

for region in "${!REGION_FILES[@]}"; do
    FILE="ors-docker/files/${REGION_FILES[$region]}"
    if [ ! -f "$FILE" ]; then
        echo -e "${YELLOW}⚠ ${region} file not found: $FILE${NC}"
        echo "  Download: wget -O $FILE ${REGION_URLS[$region]}"
    else
        SIZE=$(du -h "$FILE" | cut -f1)
        echo -e "${GREEN}✓ ${region} file found (${SIZE})${NC}"
    fi
done

# Step 4: Summary
echo ""
echo -e "${GREEN}=========================================="
echo "Setup Complete!"
echo "==========================================${NC}"
echo ""
echo "Next steps:"
echo ""
echo "1. Download OSM files for regions you want (if not already downloaded)"
echo ""
echo "2. Build graphs ONE AT A TIME (to avoid memory issues):"
echo "   docker compose -f docker-compose.pacific.yml up -d"
echo "   # Wait for build to complete, then:"
echo "   docker compose -f docker-compose.pacific.yml down"
echo "   # Repeat for other regions..."
echo ""
echo "3. After all graphs are built, set REBUILD_GRAPHS: False in all compose files"
echo ""
echo "4. Run only the regions you need (1-2 at a time on 32GB RAM):"
echo "   docker compose -f docker-compose.pacific.yml up -d"
echo "   docker compose -f docker-compose.northeast.yml up -d"
echo ""
echo "5. Test endpoints:"
echo "   Pacific:    curl http://localhost:8080/ors/v2/health"
echo "   West:       curl http://localhost:8081/ors/v2/health"
echo "   Northeast:  curl http://localhost:8082/ors/v2/health"
echo "   South:      curl http://localhost:8083/ors/v2/health"
echo "   Midwest:    curl http://localhost:8084/ors/v2/health"
echo ""
echo -e "${YELLOW}Remember: Build graphs separately, then run only what you need!${NC}"

