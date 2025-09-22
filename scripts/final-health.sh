#!/bin/bash

echo "✅ TMS System Health Status"
echo "=========================="

# Backend
if curl -s http://localhost:8080/health >/dev/null 2>&1; then
    echo "✅ Backend API: Healthy"
else
    echo "❌ Backend API: Failed"
fi

# API
if curl -s http://localhost:8080/api/v1/ping >/dev/null 2>&1; then
    echo "✅ API: Connected"
else
    echo "❌ API: Failed"
fi

# Frontend
if curl -s http://localhost:3000 >/dev/null 2>&1; then
    echo "✅ Frontend: Running"
else
    echo "❌ Frontend: Failed"
fi

echo ""
echo "🌐 System Ready!"
echo "- Frontend: http://localhost:3000"
echo "- Backend: http://localhost:8080"
echo "- Login: admin@tms.com / password"