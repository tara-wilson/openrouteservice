#!/bin/bash
# Helper script to build OpenRouteService for a single US state
# Usage: ./build-state.sh california

set -e

STATE=$1
if [ -z "$STATE" ]; then
    echo "Usage: $0 <state-name>"
    echo "Example: $0 california"
    echo ""
    echo "Available states:"
    echo "  california, texas, florida, new-york, pennsylvania, illinois, ohio, georgia,"
    echo "  north-carolina, michigan, new-jersey, virginia, washington, arizona, massachusetts"
    exit 1
fi

STATE_FILE="ors-docker/files/${STATE}-latest.osm.pbf"
STATE_URL="https://download.geofabrik.de/north-america/us/${STATE}-latest.osm.pbf"

echo "=========================================="
echo "Building ORS for: $STATE"
echo "=========================================="

# Check if file exists
if [ ! -f "$STATE_FILE" ]; then
    echo "Downloading ${STATE} OSM file..."
    wget -O "$STATE_FILE" "$STATE_URL"
    echo "Download complete!"
else
    echo "OSM file already exists: $STATE_FILE"
fi

# Update config to use state file
echo "Updating configuration..."
sed -i.bak "s|source_file:.*|source_file: /home/ors/files/${STATE}-latest.osm.pbf|" ors-docker/config/ors-config.yml

# Update docker-compose to use state-specific container name
sed -i.bak "s|container_name:.*|container_name: ors-app-${STATE}|" docker-compose.us.yml

echo ""
echo "Configuration updated!"
echo ""
echo "Next steps:"
echo "1. Review the config: ors-docker/config/ors-config.yml"
echo "2. Start the build:"
echo "   docker compose -f docker-compose.us.yml up -d"
echo "3. Monitor logs:"
echo "   docker compose -f docker-compose.us.yml logs -f"
echo ""
echo "Note: State files are much smaller and should build successfully on 32GB RAM."

