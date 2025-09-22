#!/bin/bash

echo "🔧 Quick Flutter Web Test"
echo "========================"

# Test backend login
echo "1. Testing backend login..."
RESPONSE=$(curl -s -X POST http://localhost:8080/api/v1/login \
  -H "Content-Type: application/json" \
  -d '{"username":"admin@tms.com","password":"admin123"}')

if echo "$RESPONSE" | grep -q "token"; then
    echo "✅ Backend login working"
    TOKEN=$(echo "$RESPONSE" | grep -o '"token":"[^"]*"' | cut -d'"' -f4)
    echo "Token: ${TOKEN:0:50}..."
else
    echo "❌ Backend login failed: $RESPONSE"
    exit 1
fi

# Start Flutter web with proxy
echo "2. Starting Flutter web..."
cd frontend/aplikasi_tms

# Create simple proxy server for CORS
cat > cors_proxy.py << 'EOF'
#!/usr/bin/env python3
import http.server
import socketserver
import urllib.request
import json
from urllib.parse import urlparse

class CORSProxyHandler(http.server.SimpleHTTPRequestHandler):
    def do_OPTIONS(self):
        self.send_response(200)
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS')
        self.send_header('Access-Control-Allow-Headers', 'Origin, Content-Type, Accept, Authorization')
        self.end_headers()
    
    def do_POST(self):
        if self.path.startswith('/api/'):
            # Proxy to backend
            url = f'http://localhost:8080{self.path}'
            content_length = int(self.headers['Content-Length'])
            post_data = self.rfile.read(content_length)
            
            req = urllib.request.Request(url, data=post_data)
            req.add_header('Content-Type', 'application/json')
            
            try:
                with urllib.request.urlopen(req) as response:
                    data = response.read()
                    self.send_response(200)
                    self.send_header('Access-Control-Allow-Origin', '*')
                    self.send_header('Content-Type', 'application/json')
                    self.end_headers()
                    self.wfile.write(data)
            except Exception as e:
                self.send_response(500)
                self.send_header('Access-Control-Allow-Origin', '*')
                self.end_headers()
                self.wfile.write(str(e).encode())
        else:
            super().do_POST()

PORT = 3007
with socketserver.TCPServer(("", PORT), CORSProxyHandler) as httpd:
    print(f"CORS Proxy server at http://localhost:{PORT}")
    httpd.serve_forever()
EOF

python3 cors_proxy.py &
PROXY_PID=$!

echo "✅ CORS Proxy started on port 3007"
echo "🌐 Flutter Web: http://localhost:3008"
echo "🔧 CORS Proxy: http://localhost:3007"
echo "📋 Demo Login: admin@tms.com / admin123"
echo ""
echo "Press Ctrl+C to stop"

# Start Flutter web
flutter pub get
flutter run -d web-server --web-port=3008 --web-hostname=0.0.0.0

# Cleanup
kill $PROXY_PID 2>/dev/null || true