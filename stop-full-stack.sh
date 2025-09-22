#!/bin/bash

echo "🛑 Stopping Full Stack TMS Application"
echo "======================================"

# Stop Flutter web
if [ -f "frontend/aplikasi_tms/flutter_web.pid" ]; then
    FLUTTER_PID=$(cat frontend/aplikasi_tms/flutter_web.pid)
    if ps -p "$FLUTTER_PID" > /dev/null 2>&1; then
        echo "Stopping Flutter web (PID: $FLUTTER_PID)..."
        kill "$FLUTTER_PID"
        rm frontend/aplikasi_tms/flutter_web.pid
        echo "✅ Flutter web stopped"
    else
        echo "Flutter web process not found"
        rm -f frontend/aplikasi_tms/flutter_web.pid
    fi
else
    echo "No Flutter web PID file found"
fi

# Stop Docker services
echo "Stopping Docker services..."
docker compose down

echo ""
echo "✅ All services stopped"
echo "Logs preserved in:"
echo "  - frontend/aplikasi_tms/flutter_web.log"
echo "  - Docker logs: docker logs tms-backend"