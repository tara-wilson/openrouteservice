# Cross-Region Routing Options

With the current multi-region setup, **each region is isolated**. You cannot route across regions with a single request.

## Current Limitation

- ✅ **Within same region**: Works (e.g., NY to PA - both Northeast)
- ❌ **Across regions**: Doesn't work (e.g., CA to NV - different instances)

## Solutions for Cross-Region Routing

### Option 1: Merge All Regions (Single Instance)

Merge all region OSM files into one combined file:

```bash
# Merge all regions
./merge-regions.sh

# This creates: ors-docker/files/us-all-regions-merged.osm.pbf (~10-15GB)

# Update config to use merged file
# Edit ors-config.us.yml:
#   source_file: /home/ors/files/us-all-regions-merged.osm.pbf

# Build graphs (requires 64GB+ RAM)
docker compose -f docker-compose.us.yml up -d
```

**Pros:**
- Full cross-region routing
- Single endpoint
- Simpler setup

**Cons:**
- Requires 64GB+ RAM to build
- Larger graph files
- Longer build time

### Option 2: Multi-Region with Routing Proxy

Create a proxy/router that:
1. Detects which regions a route crosses
2. Makes multiple requests to different region instances
3. Combines results

**Pros:**
- Works with 32GB RAM (build regions separately)
- Can run only needed regions

**Cons:**
- More complex setup
- Requires custom proxy code
- Multiple API calls per request

### Option 3: Build Adjacent Regions Together

Build regions that share borders together:

- **West Coast**: Pacific + West (CA, OR, WA, NV + AZ, CO, UT, etc.)
- **East Coast**: Northeast + South (NY, PA, etc. + TX, FL, GA, etc.)
- **Central**: Midwest + parts of West/South

**Pros:**
- Cross-region routing for adjacent areas
- Manageable memory requirements

**Cons:**
- Still can't route coast-to-coast
- More complex setup

### Option 4: Use GraphHopper's Multi-Region Support (Advanced)

GraphHopper supports loading multiple graphs. You'd need to:
1. Build graphs for each region separately
2. Configure ORS to load multiple graphs
3. Use GraphHopper's multi-graph routing

**Pros:**
- Efficient memory usage
- Cross-region routing

**Cons:**
- Requires code changes to ORS
- Complex configuration

## Recommendation

**For 32GB RAM server:**
- Use **Option 3** (adjacent regions) if you need some cross-region routing
- Or accept the limitation and route within regions only

**If you upgrade to 64GB+ RAM:**
- Use **Option 1** (merge all regions) for full US coverage

## Quick Test

To test if cross-region routing works:

```bash
# This will FAIL (different regions):
curl 'http://localhost:8080/ors/v2/directions/driving-car?start=-122.4194,37.7749&end=-111.8910,40.7608'
# CA (Pacific) to UT (West) - different instances

# This will WORK (same region):
curl 'http://localhost:8082/ors/v2/directions/driving-car?start=-74.006,40.7128&end=-75.1652,39.9526'
# NY to PA - both Northeast
```

