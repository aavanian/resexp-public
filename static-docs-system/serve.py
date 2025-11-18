#!/usr/bin/env python3
"""
Simple HTTP server for viewing documentation locally.

This server allows you to view the documentation system via http://localhost:8000
which avoids CORS issues that can occur with the file:// protocol in some browsers.

Usage:
    python3 serve.py
    # or
    ./serve.py

Then open http://localhost:8000 in your browser.
"""

import http.server
import socketserver
import os
import sys

PORT = 8000

# Change to the directory containing this script
os.chdir(os.path.dirname(os.path.abspath(__file__)))

Handler = http.server.SimpleHTTPRequestHandler

print(f"""
╔════════════════════════════════════════════════════════════╗
║  Static Documentation Server                               ║
╠════════════════════════════════════════════════════════════╣
║                                                            ║
║  Server running at: http://localhost:{PORT}                   ║
║                                                            ║
║  Press Ctrl+C to stop the server                          ║
║                                                            ║
╚════════════════════════════════════════════════════════════╝
""")

try:
    with socketserver.TCPServer(("", PORT), Handler) as httpd:
        print(f"Serving at http://localhost:{PORT}")
        print(f"Open your browser to: http://localhost:{PORT}/index.html\n")
        httpd.serve_forever()
except KeyboardInterrupt:
    print("\n\nServer stopped.")
    sys.exit(0)
except OSError as e:
    if e.errno == 48:  # Address already in use
        print(f"\n❌ Error: Port {PORT} is already in use.")
        print(f"   Try a different port or stop the other server.\n")
        sys.exit(1)
    else:
        raise
