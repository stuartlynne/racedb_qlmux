#!!/usr/local/bin/python3

import http.server
import socketserver

PORT = 8000
Handler = http.server.SimpleHTTPRequestHandler

with socketserver.TCPServer(("", PORT), Handler) as httpd:
    print("serving at port", PORT)
    try:
        httpd.serve_forever()
    except Execption as e:
        print('simple http: %s' % (e))

exit(0)
