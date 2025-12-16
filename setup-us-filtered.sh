#!/bin/bash
# Setup script for FULL US with highway filtering
# Filters OSM to only highways - reduces file size significantly

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo "=========================================="
echo "US Setup with Highway Filtering"
echo "=========================================="
echo ""
echo "This filters the US OSM file to ONLY highways, reducing size by ~70%"
echo "This should work on 32GB RAM!"
echo ""

# Check if osmium-tool is installed
if ! command -v osmium &> /dev/null; then
    echo -e "${YELLOW}Installing osmium-tool...${NC}"
    sudo apt-get update
    sudo apt-get install -y osmium-tool
fi

US_FILE="ors-docker/files/us-latest.osm.pbf"
FILTERED_FILE="ors-docker/files/us-highways-only.osm.pbf"
US_URL="https://download.geofabrik.de/north-america/us-latest.osm.pbf"

# Step 1: Download US file if needed
if [ ! -f "$US_FILE" ]; then
    echo -e "${GREEN}Downloading US OSM file...${NC}"
    echo "This is ~8GB and will take 30-60 minutes..."
    wget -O "$US_FILE" "$US_URL"
    echo -e "${GREEN}✓ Download complete${NC}"
else
    SIZE=$(du -h "$US_FILE" | cut -f1)
    echo -e "${GREEN}✓ US file already exists: ${SIZE}${NC}"
fi

# Step 2: Filter to highways only
echo ""
echo -e "${GREEN}Filtering to highways only (this will take 1-2 hours)...${NC}"
echo "This reduces file size by ~70% and memory usage significantly"

osmium tags-filter "$US_FILE" \
    nwr/highway \
    -o "$FILTERED_FILE"

if [ $? -eq 0 ]; then
    ORIGINAL_SIZE=$(du -h "$US_FILE" | cut -f1)
    FILTERED_SIZE=$(du -h "$FILTERED_FILE" | cut -f1)
    echo -e "${GREEN}✓ Filter complete!${NC}"
    echo "  Original: ${ORIGINAL_SIZE}"
    echo "  Filtered: ${FILTERED_SIZE}"
else
    echo -e "${RED}✗ Filter failed!${NC}"
    exit 1
fi

# Step 3: Update config
echo ""
echo -e "${GREEN}Updating configuration...${NC}"
if [ -f "ors-docker/config/ors-config.yml" ]; then
    sed -i.bak 's|source_file:.*|source_file: /home/ors/files/us-highways-only.osm.pbf|' ors-docker/config/ors-config.yml
    echo -e "${GREEN}✓ Configuration updated${NC}"
else
    cp ors-config.us.yml ors-docker/config/ors-config.yml
    sed -i.bak 's|source_file:.*|source_file: /home/ors/files/us-highways-only.osm.pbf|' ors-docker/config/ors-config.yml
    echo -e "${GREEN}✓ Configuration created${NC}"
fi

echo ""
echo -e "${GREEN}=========================================="
echo "Setup Complete!"
echo "==========================================${NC}"
echo ""
echo "Filtered file: ${FILTERED_SIZE} (vs ${ORIGINAL_SIZE} original)"
echo "This should work on 32GB RAM!"
echo ""
echo "Next steps:"
echo "1. Set REBUILD_GRAPHS: True in docker-compose.us.yml"
echo "2. Start build:"
echo "   docker compose -f docker-compose.us.yml up -d"
echo "3. Monitor:"
echo "   docker compose -f docker-compose.us.yml logs -f"

