#!/bin/bash
# Setup script for FULL US coverage - merged all regions
# This enables cross-region routing across the entire country

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo "=========================================="
echo "FULL US Coverage Setup"
echo "=========================================="
echo ""
echo "This will merge ALL US regions into one file for FULL COUNTRY routing."
echo ""

# Check if osmium-tool is installed
if ! command -v osmium &> /dev/null; then
    echo -e "${YELLOW}Installing osmium-tool...${NC}"
    sudo apt-get update
    sudo apt-get install -y osmium-tool
fi

REGIONS=("pacific" "west" "northeast" "south" "midwest")
FILES_DIR="ors-docker/files"
MERGED_FILE="${FILES_DIR}/us-all-regions-merged.osm.pbf"

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

# Step 1: Download missing files
echo -e "${GREEN}Step 1: Checking OSM files...${NC}"
ALL_EXIST=true
for region in "${REGIONS[@]}"; do
    FILE="${FILES_DIR}/${REGION_FILES[$region]}"
    if [ ! -f "$FILE" ]; then
        echo -e "${YELLOW}Downloading ${region}...${NC}"
        wget -O "$FILE" "${REGION_URLS[$region]}"
        echo -e "${GREEN}✓ ${region} downloaded${NC}"
        ALL_EXIST=false
    else
        SIZE=$(du -h "$FILE" | cut -f1)
        echo -e "${GREEN}✓ ${region}: ${SIZE}${NC}"
    fi
done

# Step 2: Merge files
echo ""
echo -e "${GREEN}Step 2: Merging all regions into one file...${NC}"
echo -e "${YELLOW}This will take 30-60 minutes...${NC}"

osmium merge \
    "${FILES_DIR}/${REGION_FILES[pacific]}" \
    "${FILES_DIR}/${REGION_FILES[west]}" \
    "${FILES_DIR}/${REGION_FILES[northeast]}" \
    "${FILES_DIR}/${REGION_FILES[south]}" \
    "${FILES_DIR}/${REGION_FILES[midwest]}" \
    -o "$MERGED_FILE"

if [ $? -eq 0 ]; then
    MERGED_SIZE=$(du -h "$MERGED_FILE" | cut -f1)
    echo -e "${GREEN}✓ Merge complete! Merged file: ${MERGED_SIZE}${NC}"
else
    echo -e "${RED}✗ Merge failed!${NC}"
    exit 1
fi

# Step 3: Update config
echo ""
echo -e "${GREEN}Step 3: Updating configuration...${NC}"
if [ -f "ors-docker/config/ors-config.yml" ]; then
    sed -i.bak 's|source_file:.*|source_file: /home/ors/files/us-all-regions-merged.osm.pbf|' ors-docker/config/ors-config.yml
    sed -i.bak 's|graph_path: graphs|graph_path: graphs/us-full|' ors-docker/config/ors-config.yml
    echo -e "${GREEN}✓ Configuration updated${NC}"
else
    cp ors-config.us.yml ors-docker/config/ors-config.yml
    echo -e "${GREEN}✓ Configuration created${NC}"
fi

# Step 4: Create graph directory
mkdir -p ors-docker/graphs/us-full

echo ""
echo -e "${GREEN}=========================================="
echo "Setup Complete!"
echo "==========================================${NC}"
echo ""
echo -e "${RED}IMPORTANT:${NC}"
echo "  - Merged file size: ${MERGED_SIZE}"
echo "  - Building graphs requires significant memory"
echo "  - With optimizations, may work on 32GB RAM"
echo ""
echo "Next steps:"
echo "1. Set REBUILD_GRAPHS: True in docker-compose.us.yml"
echo "2. Start build:"
echo "   docker compose -f docker-compose.us.yml up -d"
echo "3. Monitor:"
echo "   docker compose -f docker-compose.us.yml logs -f"
echo ""
echo -e "${GREEN}This will give you FULL US cross-region routing!${NC}"

