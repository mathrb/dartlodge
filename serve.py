#!/usr/bin/env python3
import http.server
import socketserver

PORT = 8087

class WasmHandler(http.server.SimpleHTTPRequestHandler):
    def guess_type(self, path):
        if str(path).endswith('.wasm'):
            return 'application/wasm'
        return super().guess_type(path)

    def end_headers(self):
        super().end_headers()

with socketserver.TCPServer(("0.0.0.0", PORT), WasmHandler) as httpd:
    print(f"Serving on http://0.0.0.0:{PORT}")
    httpd.serve_forever()
