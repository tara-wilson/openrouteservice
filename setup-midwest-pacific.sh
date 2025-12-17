#!/bin/bash
# Setup script for Midwest + Pacific merged regions
# This gives you cross-region routing between these two regions

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo "=========================================="
echo "Midwest + Pacific Merged Setup"
echo "=========================================="
echo ""
echo "This will merge US Midwest and Pacific regions."
echo "Coverage: IL, OH, MI, IN, CA, OR, WA, NV, HI, etc."
echo ""

# Check if osmium-tool is installed
if ! command -v osmium &> /dev/null; then
    echo -e "${YELLOW}Installing osmium-tool...${NC}"
    sudo apt-get update
    sudo apt-get install -y osmium-tool
fi

FILES_DIR="ors-docker/files"
MIDWEST_FILE="${FILES_DIR}/us-midwest-latest.osm.pbf"
PACIFIC_FILE="${FILES_DIR}/us-pacific-latest.osm.pbf"
MERGED_FILE="${FILES_DIR}/us-midwest-pacific-merged.osm.pbf"

MIDWEST_URL="https://download.geofabrik.de/north-america/us-midwest-latest.osm.pbf"
PACIFIC_URL="https://download.geofabrik.de/north-america/us-pacific-latest.osm.pbf"

# Step 1: Download files if needed
echo -e "${GREEN}Step 1: Checking OSM files...${NC}"

if [ ! -f "$MIDWEST_FILE" ]; then
    echo -e "${YELLOW}Downloading Midwest...${NC}"
    wget -O "$MIDWEST_FILE" "$MIDWEST_URL"
    echo -e "${GREEN}✓ Midwest downloaded${NC}"
else
    SIZE=$(du -h "$MIDWEST_FILE" | cut -f1)
    echo -e "${GREEN}✓ Midwest: ${SIZE}${NC}"
fi

if [ ! -f "$PACIFIC_FILE" ]; then
    echo -e "${YELLOW}Downloading Pacific...${NC}"
    wget -O "$PACIFIC_FILE" "$PACIFIC_URL"
    echo -e "${GREEN}✓ Pacific downloaded${NC}"
else
    SIZE=$(du -h "$PACIFIC_FILE" | cut -f1)
    echo -e "${GREEN}✓ Pacific: ${SIZE}${NC}"
fi

# Step 2: Merge files
echo ""
echo -e "${GREEN}Step 2: Merging Midwest + Pacific...${NC}"
echo -e "${YELLOW}This will take 10-20 minutes...${NC}"

osmium merge \
    "$MIDWEST_FILE" \
    "$PACIFIC_FILE" \
    -o "$MERGED_FILE"

if [ $? -eq 0 ]; then
    MERGED_SIZE=$(du -h "$MERGED_FILE" | cut -f1)
    MIDWEST_SIZE=$(du -h "$MIDWEST_FILE" | cut -f1)
    PACIFIC_SIZE=$(du -h "$PACIFIC_FILE" | cut -f1)
    echo -e "${GREEN}✓ Merge complete!${NC}"
    echo "  Midwest: ${MIDWEST_SIZE}"
    echo "  Pacific: ${PACIFIC_SIZE}"
    echo "  Merged: ${MERGED_SIZE}"
else
    echo -e "${RED}✗ Merge failed!${NC}"
    exit 1
fi

# Step 3: Update config
echo ""
echo -e "${GREEN}Step 3: Updating configuration...${NC}"
if [ -f "ors-docker/config/ors-config.yml" ]; then
    sed -i.bak 's|source_file:.*|source_file: /home/ors/files/us-midwest-pacific-merged.osm.pbf|' ors-docker/config/ors-config.yml
    sed -i.bak 's|graph_path: graphs|graph_path: graphs/midwest-pacific|' ors-docker/config/ors-config.yml
    echo -e "${GREEN}✓ Configuration updated${NC}"
else
    cp ors-config.us.yml ors-docker/config/ors-config.yml
    sed -i.bak 's|source_file:.*|source_file: /home/ors/files/us-midwest-pacific-merged.osm.pbf|' ors-docker/config/ors-config.yml
    sed -i.bak 's|graph_path: graphs|graph_path: graphs/midwest-pacific|' ors-docker/config/ors-config.yml
    echo -e "${GREEN}✓ Configuration created${NC}"
fi

# Step 4: Create graph directory
mkdir -p ors-docker/graphs/midwest-pacific

echo ""
echo -e "${GREEN}=========================================="
echo "Setup Complete!"
echo "==========================================${NC}"
echo ""
echo "Coverage includes:"
echo "  Midwest: IL, OH, MI, IN, WI, MN, IA, MO, ND, SD, NE, KS"
echo "  Pacific: CA, OR, WA, NV, HI"
echo ""
echo "Merged file size: ${MERGED_SIZE}"
echo "This should work on 32GB RAM!"
echo ""
echo "Next steps:"
echo "1. Set REBUILD_GRAPHS: True in docker-compose.us.yml"
echo "2. Start build:"
echo "   docker compose -f docker-compose.us.yml up -d"
echo "3. Monitor:"
echo "   docker compose -f docker-compose.us.yml logs -f"
echo ""
echo -e "${GREEN}You'll have cross-region routing between Midwest and Pacific!${NC}"

