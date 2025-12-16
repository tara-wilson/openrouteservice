#!/bin/bash
# Setup script for US Northeast region
# Includes: NY, PA, NJ, MA, CT, VT, NH, ME, RI

set -e

echo "=========================================="
echo "Setting up OpenRouteService for US Northeast"
echo "=========================================="
echo ""

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Step 1: Download US Northeast OSM file
echo -e "${GREEN}Step 1: Downloading US Northeast OSM file...${NC}"
NORTHEAST_FILE="ors-docker/files/us-northeast-latest.osm.pbf"
NORTHEAST_URL="https://download.geofabrik.de/north-america/us-northeast-latest.osm.pbf"

if [ ! -f "$NORTHEAST_FILE" ]; then
    echo "Downloading from Geofabrik (this may take 10-15 minutes)..."
    wget -O "$NORTHEAST_FILE" "$NORTHEAST_URL"
    echo -e "${GREEN}✓ Download complete!${NC}"
else
    echo -e "${YELLOW}File already exists: $NORTHEAST_FILE${NC}"
    read -p "Re-download? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        rm "$NORTHEAST_FILE"
        wget -O "$NORTHEAST_FILE" "$NORTHEAST_URL"
        echo -e "${GREEN}✓ Re-download complete!${NC}"
    fi
fi

# Step 2: Update config
echo ""
echo -e "${GREEN}Step 2: Updating configuration...${NC}"
if grep -q "us-northeast-latest.osm.pbf" ors-docker/config/ors-config.yml; then
    echo -e "${GREEN}✓ Config already points to US Northeast${NC}"
else
    # Update the config file
    sed -i.bak 's|source_file:.*|source_file: /home/ors/files/us-northeast-latest.osm.pbf|' ors-docker/config/ors-config.yml
    echo -e "${GREEN}✓ Configuration updated${NC}"
fi

# Step 3: Check file size
echo ""
echo -e "${GREEN}Step 3: Checking file size...${NC}"
if [ -f "$NORTHEAST_FILE" ]; then
    FILE_SIZE=$(du -h "$NORTHEAST_FILE" | cut -f1)
    echo "US Northeast OSM file size: $FILE_SIZE"
    echo -e "${GREEN}✓ File ready${NC}"
else
    echo -e "${YELLOW}⚠ File not found: $NORTHEAST_FILE${NC}"
fi

# Step 4: Summary
echo ""
echo -e "${GREEN}=========================================="
echo "Setup Complete!"
echo "==========================================${NC}"
echo ""
echo "US Northeast includes:"
echo "  New York, Pennsylvania, New Jersey, Massachusetts,"
echo "  Connecticut, Vermont, New Hampshire, Maine, Rhode Island"
echo ""
echo "Next steps:"
echo ""
echo "1. Make sure REBUILD_GRAPHS is True in docker-compose.us.yml"
echo ""
echo "2. Start the build:"
echo "   docker compose -f docker-compose.us.yml down"
echo "   docker compose -f docker-compose.us.yml up -d"
echo ""
echo "3. Monitor the build (will take 1-2 hours):"
echo "   docker compose -f docker-compose.us.yml logs -f"
echo ""
echo "4. Test routing once ready:"
echo "   curl 'http://localhost:8080/ors/v2/directions/driving-car?start=-74.006,40.7128&end=-73.9352,40.7589'"
echo ""
echo -e "${GREEN}US Northeast should build successfully on 32GB RAM!${NC}"

