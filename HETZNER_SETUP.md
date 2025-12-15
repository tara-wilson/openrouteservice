# OpenRouteService Setup for Hetzner Server - United States

This guide will help you set up OpenRouteService on a Hetzner server configured for the entire United States.

## Prerequisites

- Hetzner server with:
  - **Minimum 32GB RAM** (64GB+ recommended for better performance)
  - **100GB+ disk space** (for OSM data, graphs, and elevation cache)
  - Ubuntu 22.04 or Debian 12 (recommended)
- SSH access to your server
- Basic knowledge of Docker and Linux commands

## Quick Start

### 1. Connect to Your Hetzner Server

```bash
ssh root@your-hetzner-server-ip
```

### 2. Create a Non-Root User (Recommended)

```bash
adduser orsuser
usermod -aG sudo orsuser
su - orsuser
```

### 3. Clone the Repository

```bash
git clone https://github.com/GIScience/openrouteservice.git
cd openrouteservice
```

Or if you already have the repository:

```bash
cd /path/to/openrouteservice
```

### 4. Run the Setup Script

```bash
./setup-hetzner-us.sh
```

The script will:
- Check and install Docker if needed
- Create necessary directories
- Copy configuration files
- Optionally download the US OSM PBF file
- Configure system settings
- Build the Docker image

### 5. Start the Service

```bash
docker compose -f docker-compose.us.yml up -d
```

### 6. Monitor the Build Process

Graph building for the entire US can take **several hours** (4-12 hours depending on server specs). Monitor progress with:

```bash
docker compose -f docker-compose.us.yml logs -f
```

## Manual Setup (Alternative)

If you prefer to set up manually:

### Step 1: Install Docker

```bash
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER
# Log out and back in for group changes to take effect
```

### Step 2: Create Directories

```bash
mkdir -p ors-docker/{config,files,graphs,elevation_cache,logs}
chmod -R 755 ors-docker
```

### Step 3: Download US OSM Data

Download the US OSM PBF file from Geofabrik:

```bash
cd ors-docker/files
wget https://download.geofabrik.de/north-america/us-latest.osm.pbf
```

**Note:** The US file is approximately 5-10GB. Download time depends on your connection speed.

### Step 4: Configure System Settings

For large builds, increase the memory mapping limit:

```bash
echo "vm.max_map_count=81920" | sudo tee -a /etc/sysctl.conf
sudo sysctl -p
```

### Step 5: Copy Configuration

```bash
cp ors-config.us.yml ors-docker/config/ors-config.yml
```

### Step 6: Adjust Memory Settings

Edit `docker-compose.us.yml` and adjust memory settings based on your server RAM:

- **32GB RAM**: `XMS: 8g`, `XMX: 24g`
- **64GB RAM**: `XMS: 16g`, `XMX: 48g`
- **128GB RAM**: `XMS: 32g`, `XMX: 96g`

### Step 7: Build and Start

```bash
docker compose -f docker-compose.us.yml build
docker compose -f docker-compose.us.yml up -d
```

## Configuration

### Memory Requirements

The memory needed depends on:
- **OSM PBF size**: US file is ~5-10GB
- **Number of profiles**: Each enabled profile multiplies memory needs
- **Rule of thumb**: `PBF_size × profiles × 2 = minimum RAM needed`

For US with `driving-car` profile:
- Minimum: 10GB × 1 × 2 = **20GB RAM**
- Recommended: **32GB+ RAM** for better performance

### Available Profiles

The default configuration enables:
- `driving-car`: Standard car routing (enabled by default)

You can enable additional profiles by editing `ors-docker/config/ors-config.yml`:
- `driving-hgv`: Heavy goods vehicles
- `cycling-regular`: Regular cycling
- `cycling-mountain`: Mountain biking
- `cycling-road`: Road cycling
- `foot-walking`: Walking
- `foot-hiking`: Hiking

**Note:** Each additional profile significantly increases memory requirements and build time.

### Updating OSM Data

To update your OSM data:

1. Download the latest US OSM file:
   ```bash
   cd ors-docker/files
   wget -O us-latest.osm.pbf https://download.geofabrik.de/north-america/us-latest.osm.pbf
   ```

2. Rebuild graphs:
   ```bash
   docker compose -f docker-compose.us.yml down
   # Edit docker-compose.us.yml and set REBUILD_GRAPHS: True
   docker compose -f docker-compose.us.yml up -d
   ```

## Usage

### Check Service Health

```bash
curl http://localhost:8080/ors/v2/health
```

### Test Routing

Example: Route from New York to Boston

```bash
curl 'http://localhost:8080/ors/v2/directions/driving-car?start=-74.006,40.7128&end=-71.0589,42.3601'
```

### API Endpoints

Once running, the following endpoints are available:

- **Directions**: `http://localhost:8080/ors/v2/directions`
- **Isochrones**: `http://localhost:8080/ors/v2/isochrones`
- **Matrix**: `http://localhost:8080/ors/v2/matrix`
- **Snap**: `http://localhost:8080/ors/v2/snap`
- **Health**: `http://localhost:8080/ors/v2/health`
- **Status**: `http://localhost:8080/ors/v2/status`
- **Swagger UI**: `http://localhost:8080/swagger-ui`

## Monitoring

### View Logs

```bash
# Follow logs
docker compose -f docker-compose.us.yml logs -f

# View last 100 lines
docker compose -f docker-compose.us.yml logs --tail=100
```

### Check Container Status

```bash
docker compose -f docker-compose.us.yml ps
```

### Monitor Resource Usage

```bash
docker stats ors-app-us
```

## Troubleshooting

### Out of Memory Errors

If you see out of memory errors:

1. Reduce `XMX` in `docker-compose.us.yml`
2. Disable unused profiles in `ors-config.yml`
3. Consider using a smaller region (individual states)

### Graph Build Fails

1. Check available disk space: `df -h`
2. Check logs: `docker compose -f docker-compose.us.yml logs`
3. Verify OSM file integrity
4. Ensure `vm.max_map_count` is set correctly

### Service Not Responding

1. Check if container is running: `docker ps`
2. Check health endpoint: `curl http://localhost:8080/ors/v2/health`
3. Review logs for errors
4. Verify port 8080 is not blocked by firewall

### Slow Performance

- Increase RAM allocation
- Enable fewer profiles
- Use SSD storage for better I/O performance
- Consider using a more powerful Hetzner server instance

## Security Considerations

### Firewall Setup

Configure UFW firewall:

```bash
sudo ufw allow 22/tcp    # SSH
sudo ufw allow 8080/tcp  # ORS API
sudo ufw enable
```

### Reverse Proxy (Optional)

For production, consider using Nginx as a reverse proxy:

```nginx
server {
    listen 80;
    server_name your-domain.com;

    location / {
        proxy_pass http://localhost:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

## Maintenance

### Regular Updates

1. Pull latest code: `git pull`
2. Rebuild image: `docker compose -f docker-compose.us.yml build`
3. Restart service: `docker compose -f docker-compose.us.yml restart`

### Backup

Important directories to backup:
- `ors-docker/graphs/` - Built routing graphs
- `ors-docker/config/` - Configuration files
- `ors-docker/files/` - OSM PBF files

## Performance Tips

1. **Use SSD storage** - Significantly faster graph building and routing
2. **Allocate sufficient RAM** - More RAM = faster builds and better performance
3. **Enable only needed profiles** - Each profile increases memory and build time
4. **Monitor disk I/O** - Graph building is I/O intensive
5. **Consider regional extracts** - If you only need specific states, use state-level PBF files

## Support

- Documentation: https://giscience.github.io/openrouteservice/
- GitHub Issues: https://github.com/GIScience/openrouteservice/issues
- Community Forum: https://ask.openrouteservice.org

## Cost Estimation (Hetzner)

Approximate monthly costs:
- **CPX31** (4 vCPU, 8GB RAM): ~€8/month - *Too small for full US*
- **CPX41** (8 vCPU, 16GB RAM): ~€16/month - *Minimum, may struggle*
- **CCX33** (8 vCPU, 32GB RAM): ~€50/month - **Recommended minimum**
- **CCX43** (16 vCPU, 64GB RAM): ~€100/month - **Recommended for production**

## Next Steps

1. Test the API with various routing requests
2. Set up monitoring and alerting
3. Configure reverse proxy for domain access
4. Set up automated backups
5. Consider enabling additional profiles based on your needs

