#!/usr/bin/env python3
"""
FortifyStack demo app - deliberately tiny. Its whole job is to prove the
INFRASTRUCTURE works:

  * Renders the EC2 instance id + Availability Zone serving the request, so
    refreshing the page visibly shows the ALB spreading traffic across AZs.
  * Reads its DB credentials from AWS Secrets Manager at boot using the
    instance role (no secrets on disk / in the AMI).
  * Writes a "visit" row to RDS and shows the shared count + recent visits,
    proving every instance talks to the same Multi-AZ database.

Runtime deps (installed by user-data): boto3, pg8000  (both pure-python-friendly)
Everything else is Python standard library.
"""
import json
import os
import socket
import urllib.request
from datetime import datetime, timezone
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

import boto3
import pg8000.native

PORT = int(os.environ.get("PORT", "8080"))
SECRET_ARN = os.environ["SECRET_ARN"]
REGION = os.environ.get("AWS_REGION", "us-east-1")

_IMDS = "http://169.254.169.254/latest"


def imds(path: str) -> str:
    """Fetch an IMDSv2 metadata value; return 'unknown' if unavailable."""
    try:
        token_req = urllib.request.Request(
            f"{_IMDS}/api/token",
            method="PUT",
            headers={"X-aws-ec2-metadata-token-ttl-seconds": "60"},
        )
        token = urllib.request.urlopen(token_req, timeout=1).read().decode()
        req = urllib.request.Request(
            f"{_IMDS}/meta-data/{path}",
            headers={"X-aws-ec2-metadata-token": token},
        )
        return urllib.request.urlopen(req, timeout=1).read().decode()
    except Exception:
        return "unknown"


INSTANCE_ID = imds("instance-id")
AZ = imds("placement/availability-zone")
HOSTNAME = socket.gethostname()


def get_db_config() -> dict:
    client = boto3.client("secretsmanager", region_name=REGION)
    secret = client.get_secret_value(SecretId=SECRET_ARN)["SecretString"]
    return json.loads(secret)


DB = get_db_config()


def db_conn() -> pg8000.native.Connection:
    return pg8000.native.Connection(
        user=DB["username"],
        password=DB["password"],
        host=DB["host"],
        port=int(DB["port"]),
        database=DB["dbname"],
        timeout=5,
    )


def init_db(retries: int = 30) -> None:
    """RDS may still be warming up when the first instance boots; retry."""
    import time

    last = None
    for _ in range(retries):
        try:
            conn = db_conn()
            conn.run(
                """
                CREATE TABLE IF NOT EXISTS visits (
                    id          SERIAL PRIMARY KEY,
                    ts          TIMESTAMPTZ NOT NULL DEFAULT now(),
                    instance_id TEXT,
                    az          TEXT
                )
                """
            )
            conn.close()
            print("DB initialised", flush=True)
            return
        except Exception as e:  # noqa: BLE001
            last = e
            print(f"DB not ready, retrying: {e}", flush=True)
            time.sleep(5)
    raise RuntimeError(f"Could not initialise DB after {retries} tries: {last}")


PAGE = """<!doctype html>
<html><head><meta charset="utf-8"><title>FortifyStack</title>
<style>
 body{{font-family:system-ui,Segoe UI,Arial;background:#0b1221;color:#e6edf3;margin:0;padding:2rem}}
 .card{{max-width:760px;margin:2rem auto;background:#111a2e;border:1px solid #1f2a44;border-radius:14px;padding:2rem}}
 h1{{margin:0 0 .25rem}} .muted{{color:#8aa0c6}}
 .grid{{display:grid;grid-template-columns:1fr 1fr;gap:.75rem;margin:1.5rem 0}}
 .kv{{background:#0b1221;border:1px solid #1f2a44;border-radius:10px;padding:.75rem 1rem}}
 .kv b{{display:block;color:#8aa0c6;font-weight:500;font-size:.8rem}} .kv span{{font-size:1.05rem}}
 .big{{font-size:2.2rem;font-weight:700;color:#4ade80}}
 table{{width:100%;border-collapse:collapse;margin-top:1rem;font-size:.9rem}}
 td,th{{text-align:left;padding:.4rem .5rem;border-bottom:1px solid #1f2a44}}
 code{{color:#7dd3fc}}
</style></head><body>
<div class="card">
  <h1>FortifyStack &#9889;</h1>
  <div class="muted">Highly available 3-tier web platform on AWS &mdash; served live from EC2.</div>
  <div class="grid">
    <div class="kv"><b>Serving instance</b><span><code>{instance_id}</code></span></div>
    <div class="kv"><b>Availability Zone</b><span><code>{az}</code></span></div>
    <div class="kv"><b>Hostname</b><span><code>{hostname}</code></span></div>
    <div class="kv"><b>Database (RDS)</b><span><code>{db_host}</code></span></div>
  </div>
  <div class="muted">Total visits stored in the shared Multi-AZ database:</div>
  <div class="big">{count}</div>
  <div class="muted">Refresh the page &mdash; the serving instance / AZ changes as the load balancer spreads traffic, but the counter is shared across all of them.</div>
  <table>
    <tr><th>When (UTC)</th><th>Instance</th><th>AZ</th></tr>
    {rows}
  </table>
</div>
</body></html>"""


class Handler(BaseHTTPRequestHandler):
    def _send(self, code, body, ctype="text/html; charset=utf-8"):
        data = body.encode()
        self.send_response(code)
        self.send_header("Content-Type", ctype)
        self.send_header("Content-Length", str(len(data)))
        self.end_headers()
        self.wfile.write(data)

    def do_GET(self):  # noqa: N802
        if self.path == "/health":
            # Shallow check: process is up. Kept cheap so the ALB doesn't flap.
            self._send(200, "OK", "text/plain")
            return
        if self.path == "/health/db":
            try:
                conn = db_conn()
                conn.run("SELECT 1")
                conn.close()
                self._send(200, "DB OK", "text/plain")
            except Exception as e:  # noqa: BLE001
                self._send(503, f"DB FAIL: {e}", "text/plain")
            return

        # Main page: record a visit and show shared state.
        try:
            conn = db_conn()
            conn.run(
                "INSERT INTO visits (instance_id, az) VALUES (:i, :a)",
                i=INSTANCE_ID,
                a=AZ,
            )
            count = conn.run("SELECT count(*) FROM visits")[0][0]
            recent = conn.run(
                "SELECT ts, instance_id, az FROM visits ORDER BY id DESC LIMIT 8"
            )
            conn.close()
            rows = "".join(
                f"<tr><td>{r[0].strftime('%Y-%m-%d %H:%M:%S')}</td>"
                f"<td><code>{r[1]}</code></td><td>{r[2]}</td></tr>"
                for r in recent
            )
            html = PAGE.format(
                instance_id=INSTANCE_ID,
                az=AZ,
                hostname=HOSTNAME,
                db_host=DB["host"],
                count=count,
                rows=rows,
            )
            self._send(200, html)
        except Exception as e:  # noqa: BLE001
            self._send(500, f"App up on {INSTANCE_ID}/{AZ} but DB error: {e}", "text/plain")

    def log_message(self, *args):  # quieter logs
        return


if __name__ == "__main__":
    init_db()
    print(f"FortifyStack listening on :{PORT} ({INSTANCE_ID}/{AZ})", flush=True)
    ThreadingHTTPServer(("0.0.0.0", PORT), Handler).serve_forever()
