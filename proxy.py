#!/usr/bin/env python3
import http.server
import socketserver
import urllib.request

class CORSProxyHandler(http.server.SimpleHTTPRequestHandler):
    def do_OPTIONS(self):
        self.send_response(200)
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS')
        self.send_header('Access-Control-Allow-Headers', 'Origin, Content-Type, Accept, Authorization')
        self.end_headers()
    
    def do_POST(self):
        if self.path.startswith('/api/'):
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
                self.send_header('Content-Type', 'application/json')
                self.end_headers()
                # Sanitize error message to prevent XSS
                safe_error = "API request failed"
                self.wfile.write(f'{{"error": "{safe_error}"}}'.encode())

PORT = 3007
with socketserver.TCPServer(("", PORT), CORSProxyHandler) as httpd:
    print(f"CORS Proxy running on port {PORT}")
    httpd.serve_forever()