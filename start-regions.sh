#!/bin/bash
# Helper script to start/stop specific regions

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

ACTION=$1
REGIONS=${@:2}

if [ -z "$ACTION" ] || [ -z "$REGIONS" ]; then
    echo "Usage: $0 [start|stop|restart] [pacific|west|northeast|south|midwest|all]"
    echo ""
    echo "Examples:"
    echo "  $0 start pacific northeast"
    echo "  $0 stop all"
    echo "  $0 restart west"
    exit 1
fi

if [ "$REGIONS" = "all" ]; then
    REGIONS="pacific west northeast south midwest"
fi

for region in $REGIONS; do
    COMPOSE_FILE="docker-compose.${region}.yml"
    if [ ! -f "$COMPOSE_FILE" ]; then
        echo -e "${YELLOW}⚠ Compose file not found: $COMPOSE_FILE${NC}"
        continue
    fi
    
    case "$ACTION" in
        start)
            echo -e "${GREEN}Starting ${region}...${NC}"
            docker compose -f "$COMPOSE_FILE" up -d
            ;;
        stop)
            echo -e "${GREEN}Stopping ${region}...${NC}"
            docker compose -f "$COMPOSE_FILE" down
            ;;
        restart)
            echo -e "${GREEN}Restarting ${region}...${NC}"
            docker compose -f "$COMPOSE_FILE" restart
            ;;
        *)
            echo "Unknown action: $ACTION"
            exit 1
            ;;
    esac
done

echo ""
echo "Done! Check status with: docker ps | grep ors-app"

