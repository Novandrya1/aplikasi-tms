#!/usr/bin/env python3
import http.server
import socketserver
import urllib.request
import urllib.error
import socket
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
            
            # Validate Content-Length header
            content_length_header = self.headers.get('Content-Length')
            if not content_length_header or not content_length_header.isdigit():
                self.send_response(400)
                self.send_header('Access-Control-Allow-Origin', '*')
                self.end_headers()
                self.wfile.write(b'Invalid or missing Content-Length header')
                return
                
            content_length = int(content_length_header)
            post_data = self.rfile.read(content_length)
            
            req = urllib.request.Request(url, data=post_data)
            req.add_header('Content-Type', 'application/json')
            
            try:
                with urllib.request.urlopen(req, timeout=30) as response:
                    data = response.read()
                    self.send_response(200)
                    self.send_header('Access-Control-Allow-Origin', '*')
                    self.send_header('Content-Type', 'application/json')
                    self.end_headers()
                    self.wfile.write(data)
            except urllib.error.HTTPError as e:
                self.send_response(e.code)
                self.send_header('Access-Control-Allow-Origin', '*')
                self.end_headers()
                self.wfile.write(f'HTTP Error: {e.code}'.encode())
            except urllib.error.URLError as e:
                self.send_response(502)
                self.send_header('Access-Control-Allow-Origin', '*')
                self.end_headers()
                self.wfile.write(f'URL Error: {e.reason}'.encode())
            except socket.timeout:
                self.send_response(504)
                self.send_header('Access-Control-Allow-Origin', '*')
                self.end_headers()
                self.wfile.write(b'Request timeout')
            except Exception as e:
                self.send_response(500)
                self.send_header('Access-Control-Allow-Origin', '*')
                self.end_headers()
                self.wfile.write(f'Server Error: {str(e)}'.encode())
        else:
            super().do_POST()

PORT = 3007
with socketserver.TCPServer(("", PORT), CORSProxyHandler) as httpd:
    print(f"CORS Proxy server at http://localhost:{PORT}")
    httpd.serve_forever()
