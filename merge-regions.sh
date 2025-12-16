#!/bin/bash
# Script to merge multiple US region OSM files into one
# This allows cross-region routing in a single ORS instance

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo "=========================================="
echo "Merge US Regions for Cross-Region Routing"
echo "=========================================="
echo ""
echo "This will merge all US region OSM files into one combined file."
echo "This allows routing across regions in a single ORS instance."
echo ""
echo -e "${RED}WARNING: Merged file will be large (~10-15GB)${NC}"
echo -e "${RED}Building graphs from merged file requires 64GB+ RAM${NC}"
echo ""
read -p "Continue? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    exit 1
fi

# Check if osmium-tool is installed
if ! command -v osmium &> /dev/null; then
    echo -e "${YELLOW}osmium-tool not found. Installing...${NC}"
    sudo apt-get update
    sudo apt-get install -y osmium-tool
fi

REGIONS=("pacific" "west" "northeast" "south" "midwest")
FILES_DIR="ors-docker/files"
MERGED_FILE="${FILES_DIR}/us-all-regions-merged.osm.pbf"

# Check all files exist
echo ""
echo -e "${GREEN}Checking OSM files...${NC}"
declare -A REGION_FILES=(
    ["pacific"]="us-pacific-latest.osm.pbf"
    ["west"]="us-west-latest.osm.pbf"
    ["northeast"]="us-northeast-latest.osm.pbf"
    ["south"]="us-south-latest.osm.pbf"
    ["midwest"]="us-midwest-latest.osm.pbf"
)

ALL_EXIST=true
for region in "${REGIONS[@]}"; do
    FILE="${FILES_DIR}/${REGION_FILES[$region]}"
    if [ ! -f "$FILE" ]; then
        echo -e "${RED}✗ Missing: $FILE${NC}"
        ALL_EXIST=false
    else
        SIZE=$(du -h "$FILE" | cut -f1)
        echo -e "${GREEN}✓ ${region}: ${SIZE}${NC}"
    fi
done

if [ "$ALL_EXIST" = false ]; then
    echo ""
    echo -e "${RED}Error: Some OSM files are missing. Please download them first.${NC}"
    exit 1
fi

# Merge files
echo ""
echo -e "${GREEN}Merging OSM files (this may take 30-60 minutes)...${NC}"
osmium merge \
    "${FILES_DIR}/${REGION_FILES[pacific]}" \
    "${FILES_DIR}/${REGION_FILES[west]}" \
    "${FILES_DIR}/${REGION_FILES[northeast]}" \
    "${FILES_DIR}/${REGION_FILES[south]}" \
    "${FILES_DIR}/${REGION_FILES[midwest]}" \
    -o "$MERGED_FILE"

if [ $? -eq 0 ]; then
    MERGED_SIZE=$(du -h "$MERGED_FILE" | cut -f1)
    echo -e "${GREEN}✓ Merge complete! File size: ${MERGED_SIZE}${NC}"
    echo ""
    echo "Next steps:"
    echo "1. Update ors-config.us.yml:"
    echo "   source_file: /home/ors/files/us-all-regions-merged.osm.pbf"
    echo ""
    echo "2. You'll need 64GB+ RAM to build graphs from this merged file"
    echo ""
    echo "3. Build graphs:"
    echo "   docker compose -f docker-compose.us.yml up -d"
else
    echo -e "${RED}✗ Merge failed!${NC}"
    exit 1
fi

