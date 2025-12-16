#!/bin/bash
# Quick script to switch between California and US Northeast regions

set -e

REGION=$1
CONFIG_FILE="ors-docker/config/ors-config.yml"

if [ -z "$REGION" ]; then
    echo "Usage: $0 [california|northeast]"
    echo ""
    echo "Current region:"
    grep "source_file:" "$CONFIG_FILE" | head -1
    exit 1
fi

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

case "$REGION" in
    california)
        echo -e "${GREEN}Switching to California...${NC}"
        sed -i.bak 's|source_file:.*|source_file: /home/ors/files/california-latest.osm.pbf|' "$CONFIG_FILE"
        REGION_NAME="California"
        ;;
    northeast)
        echo -e "${GREEN}Switching to US Northeast...${NC}"
        sed -i.bak 's|source_file:.*|source_file: /home/ors/files/us-northeast-latest.osm.pbf|' "$CONFIG_FILE"
        REGION_NAME="US Northeast"
        ;;
    *)
        echo "Error: Unknown region '$REGION'"
        echo "Usage: $0 [california|northeast]"
        exit 1
        ;;
esac

echo -e "${GREEN}✓ Configuration updated to $REGION_NAME${NC}"
echo ""
echo "To apply changes:"
echo "  1. Set REBUILD_GRAPHS: True in docker-compose.us.yml (if graphs don't exist)"
echo "  2. Restart container:"
echo "     docker compose -f docker-compose.us.yml down"
echo "     docker compose -f docker-compose.us.yml up -d"
echo ""
echo "To keep existing graphs (just switch):"
echo "  Set REBUILD_GRAPHS: False in docker-compose.us.yml"
echo "  Then restart container"

