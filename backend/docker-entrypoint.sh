#!/bin/sh
set -eu

python - <<'PY'
import os
import socket
import sys
import time

host = os.getenv("DB_HOST", "db")
port = int(os.getenv("DB_PORT", "3306"))

for attempt in range(60):
    try:
        with socket.create_connection((host, port), timeout=2):
            break
    except OSError:
        time.sleep(2)
else:
    print(f"Database not reachable at {host}:{port}", file=sys.stderr)
    raise SystemExit(1)
PY

exec uvicorn main:app --host 0.0.0.0 --port 8000
