#!/bin/bash
# Quick setup script for California ORS build
# This is optimized for 32GB RAM servers

set -e

echo "=========================================="
echo "Setting up OpenRouteService for California"
echo "=========================================="
echo ""

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Step 1: Download California OSM file
echo -e "${GREEN}Step 1: Downloading California OSM file...${NC}"
CALIFORNIA_FILE="ors-docker/files/california-latest.osm.pbf"
CALIFORNIA_URL="https://download.geofabrik.de/north-america/us/california-latest.osm.pbf"

if [ ! -f "$CALIFORNIA_FILE" ]; then
    echo "Downloading from Geofabrik (this may take a few minutes)..."
    wget -O "$CALIFORNIA_FILE" "$CALIFORNIA_URL"
    echo -e "${GREEN}✓ Download complete!${NC}"
else
    echo -e "${YELLOW}File already exists: $CALIFORNIA_FILE${NC}"
    read -p "Re-download? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        rm "$CALIFORNIA_FILE"
        wget -O "$CALIFORNIA_FILE" "$CALIFORNIA_URL"
        echo -e "${GREEN}✓ Re-download complete!${NC}"
    fi
fi

# Step 2: Copy config file
echo ""
echo -e "${GREEN}Step 2: Copying configuration...${NC}"
if [ ! -f "ors-docker/config/ors-config.yml" ]; then
    cp ors-config.us.yml ors-docker/config/ors-config.yml
    echo -e "${GREEN}✓ Configuration copied${NC}"
else
    echo -e "${YELLOW}Configuration already exists${NC}"
    read -p "Overwrite with California config? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        cp ors-config.us.yml ors-docker/config/ors-config.yml
        echo -e "${GREEN}✓ Configuration updated${NC}"
    fi
fi

# Step 3: Verify config points to California
echo ""
echo -e "${GREEN}Step 3: Verifying configuration...${NC}"
if grep -q "california-latest.osm.pbf" ors-docker/config/ors-config.yml; then
    echo -e "${GREEN}✓ Config points to California file${NC}"
else
    echo -e "${YELLOW}⚠ Warning: Config doesn't point to California file${NC}"
    echo "Please verify: ors-docker/config/ors-config.yml"
fi

# Step 4: Check file size
echo ""
echo -e "${GREEN}Step 4: Checking file size...${NC}"
if [ -f "$CALIFORNIA_FILE" ]; then
    FILE_SIZE=$(du -h "$CALIFORNIA_FILE" | cut -f1)
    echo "California OSM file size: $FILE_SIZE"
    echo -e "${GREEN}✓ File ready${NC}"
else
    echo -e "${YELLOW}⚠ File not found: $CALIFORNIA_FILE${NC}"
fi

# Step 5: Summary
echo ""
echo -e "${GREEN}=========================================="
echo "Setup Complete!"
echo "==========================================${NC}"
echo ""
echo "Next steps:"
echo ""
echo "1. Review configuration:"
echo "   cat ors-docker/config/ors-config.yml | grep source_file"
echo ""
echo "2. Start the build:"
echo "   docker compose -f docker-compose.us.yml down"
echo "   docker compose -f docker-compose.us.yml up -d"
echo ""
echo "3. Monitor the build (this will take 30-60 minutes):"
echo "   docker compose -f docker-compose.us.yml logs -f"
echo ""
echo "4. Check memory usage:"
echo "   docker stats ors-app-us"
echo ""
echo "5. Once ready, test routing:"
echo "   curl 'http://localhost:8080/ors/v2/directions/driving-car?start=-122.4194,37.7749&end=-122.4094,37.7849'"
echo ""
echo -e "${GREEN}California should build successfully on 32GB RAM!${NC}"

