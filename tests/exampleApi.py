from http.server import BaseHTTPRequestHandler, HTTPServer
import json
import random

arrows = ["⬆️","↗️","➡️","↘️","⬇️"]

class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        print("Header vom Client:")
        for key, value in self.headers.items():
            print(f"{key}: {value}")

        data = {
            "value": random.randint(35, 120)/10,
            "value2": arrows[random.randint(0, 4)],
            "value3": random.randint(100, 1000)/10
        }

        body = json.dumps(data).encode("utf-8")

        self.send_response(200)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    # def log_message(self, format, *args):
    #     pass  # optional: deaktiviert Konsolen-Logs

if __name__ == "__main__":
    server = HTTPServer(("localhost", 9000), Handler)
    print("Server läuft auf http://localhost:9000")
    server.serve_forever()