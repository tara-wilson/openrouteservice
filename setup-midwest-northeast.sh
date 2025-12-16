#!/bin/bash
# Setup script for Midwest + Northeast merged regions
# This gives you cross-region routing between these two regions

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo "=========================================="
echo "Midwest + Northeast Merged Setup"
echo "=========================================="
echo ""
echo "This will merge US Midwest and Northeast regions."
echo "Coverage: IL, OH, MI, IN, NY, PA, NJ, MA, CT, VT, NH, ME, RI, etc."
echo ""

# Check if osmium-tool is installed
if ! command -v osmium &> /dev/null; then
    echo -e "${YELLOW}Installing osmium-tool...${NC}"
    sudo apt-get update
    sudo apt-get install -y osmium-tool
fi

FILES_DIR="ors-docker/files"
MIDWEST_FILE="${FILES_DIR}/us-midwest-latest.osm.pbf"
NORTHEAST_FILE="${FILES_DIR}/us-northeast-latest.osm.pbf"
MERGED_FILE="${FILES_DIR}/us-midwest-northeast-merged.osm.pbf"

MIDWEST_URL="https://download.geofabrik.de/north-america/us-midwest-latest.osm.pbf"
NORTHEAST_URL="https://download.geofabrik.de/north-america/us-northeast-latest.osm.pbf"

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

if [ ! -f "$NORTHEAST_FILE" ]; then
    echo -e "${YELLOW}Downloading Northeast...${NC}"
    wget -O "$NORTHEAST_FILE" "$NORTHEAST_URL"
    echo -e "${GREEN}✓ Northeast downloaded${NC}"
else
    SIZE=$(du -h "$NORTHEAST_FILE" | cut -f1)
    echo -e "${GREEN}✓ Northeast: ${SIZE}${NC}"
fi

# Step 2: Merge files
echo ""
echo -e "${GREEN}Step 2: Merging Midwest + Northeast...${NC}"
echo -e "${YELLOW}This will take 10-20 minutes...${NC}"

osmium merge \
    "$MIDWEST_FILE" \
    "$NORTHEAST_FILE" \
    -o "$MERGED_FILE"

if [ $? -eq 0 ]; then
    MERGED_SIZE=$(du -h "$MERGED_FILE" | cut -f1)
    MIDWEST_SIZE=$(du -h "$MIDWEST_FILE" | cut -f1)
    NORTHEAST_SIZE=$(du -h "$NORTHEAST_FILE" | cut -f1)
    echo -e "${GREEN}✓ Merge complete!${NC}"
    echo "  Midwest: ${MIDWEST_SIZE}"
    echo "  Northeast: ${NORTHEAST_SIZE}"
    echo "  Merged: ${MERGED_SIZE}"
else
    echo -e "${RED}✗ Merge failed!${NC}"
    exit 1
fi

# Step 3: Update config
echo ""
echo -e "${GREEN}Step 3: Updating configuration...${NC}"
if [ -f "ors-docker/config/ors-config.yml" ]; then
    sed -i.bak 's|source_file:.*|source_file: /home/ors/files/us-midwest-northeast-merged.osm.pbf|' ors-docker/config/ors-config.yml
    sed -i.bak 's|graph_path: graphs|graph_path: graphs/midwest-northeast|' ors-docker/config/ors-config.yml
    echo -e "${GREEN}✓ Configuration updated${NC}"
else
    cp ors-config.us.yml ors-docker/config/ors-config.yml
    echo -e "${GREEN}✓ Configuration created${NC}"
fi

# Step 4: Create graph directory
mkdir -p ors-docker/graphs/midwest-northeast

echo ""
echo -e "${GREEN}=========================================="
echo "Setup Complete!"
echo "==========================================${NC}"
echo ""
echo "Coverage includes:"
echo "  Midwest: IL, OH, MI, IN, WI, MN, IA, MO, etc."
echo "  Northeast: NY, PA, NJ, MA, CT, VT, NH, ME, RI"
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
echo -e "${GREEN}You'll have cross-region routing between Midwest and Northeast!${NC}"

