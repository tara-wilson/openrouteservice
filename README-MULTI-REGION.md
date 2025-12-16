# Running Multiple Regions in OpenRouteService

Since you've successfully built California and want to add US Northeast, here are your options:

## Option 1: Build Regions Separately (Switch Between Them)

Build each region separately and switch the config when needed:

```bash
# Build California
./setup-california.sh
# Update config to use california-latest.osm.pbf
docker compose -f docker-compose.us.yml up -d

# Later, switch to Northeast
./setup-northeast.sh
# Update config to use us-northeast-latest.osm.pbf
docker compose -f docker-compose.us.yml down
docker compose -f docker-compose.us.yml up -d
```

**Pros:** Simple, uses one instance
**Cons:** Only one region active at a time

## Option 2: Run Multiple ORS Instances (Both Active Simultaneously)

Run separate containers for each region on different ports:

### Setup:

1. **Create separate config files:**
   - `ors-docker/config/ors-config-california.yml` (points to California)
   - `ors-docker/config/ors-config-northeast.yml` (points to Northeast)

2. **Create separate docker-compose files:**
   - `docker-compose.california.yml` (port 8080)
   - `docker-compose.northeast.yml` (port 8081)

3. **Run both:**
   ```bash
   docker compose -f docker-compose.california.yml up -d
   docker compose -f docker-compose.northeast.yml up -d
   ```

**Pros:** Both regions available simultaneously
**Cons:** Uses more resources (2x memory, 2x CPU)

## Option 3: Combine OSM Files (Advanced)

Merge California and Northeast OSM files into one:

```bash
# Install osmium-tool
sudo apt-get install osmium-tool

# Merge files
osmium merge california-latest.osm.pbf us-northeast-latest.osm.pbf \
  -o california-northeast-merged.osm.pbf
```

**Pros:** Single instance, both regions
**Cons:** Larger file, may still hit memory limits

## Recommended Approach

For your 32GB RAM server, **Option 1** (switching between regions) is recommended:
- Simple to manage
- Uses resources efficiently
- Both regions can be built and stored
- Switch config when needed

## Quick Switch Script

Create a script to switch between regions:

```bash
#!/bin/bash
# switch-region.sh

REGION=$1
if [ "$REGION" = "california" ]; then
    sed -i 's|source_file:.*|source_file: /home/ors/files/california-latest.osm.pbf|' ors-docker/config/ors-config.yml
    echo "Switched to California"
elif [ "$REGION" = "northeast" ]; then
    sed -i 's|source_file:.*|source_file: /home/ors/files/us-northeast-latest.osm.pbf|' ors-docker/config/ors-config.yml
    echo "Switched to US Northeast"
else
    echo "Usage: $0 [california|northeast]"
    exit 1
fi

# Restart container
docker compose -f docker-compose.us.yml down
docker compose -f docker-compose.us.yml up -d
```

