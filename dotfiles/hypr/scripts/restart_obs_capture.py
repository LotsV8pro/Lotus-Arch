#!/usr/bin/env python3
"""
Check the OBS PipeWire screen-capture source via obs-websocket and report
whether OBS needs a restart to bring the capture back.

This intentionally does NOT remove/recreate the source: recreating a
pipewire-screen-capture-source does not re-establish the PipeWire screencast
session (the log then shows "PipeWire initialized" but never a new
"Screencast session created"), and it destroys a working capture in the
process. The only reliable recovery is restarting OBS with the portal stack
already healthy.

Exit codes (interpreted by PortalHyprland.sh):
  0  capture is healthy
  2  capture present but not rendering -> restart OBS
  3  pipewire-screen-capture-source kind not registered -> OBS started too early, restart OBS
  4  capture source missing -> restart OBS (the scene should provide it)
  5  OBS is streaming/recording; restart refused to avoid interruption
  1  connection / auth error (OBS not running or websocket disabled)
"""
import socket
import json
import hashlib
import base64
import struct
import os
import subprocess
import sys
import time

OBS_WS_HOST = "127.0.0.1"
OBS_WS_PORT = 4455
SOURCE_NAME = "Screen Capture (PipeWire)"
PIPE_KIND = "pipewire-screen-capture-source"


def load_obs_ws_password():
    """Read the OBS WebSocket password from OBS's own config (single source
    of truth) so no credential is hardcoded. Returns "" when auth is off."""
    try:
        cfg = os.path.expanduser(
            "~/.config/obs-studio/plugin_config/obs-websocket/config.json"
        )
        with open(cfg) as f:
            return json.load(f).get("server_password", "")
    except Exception:
        return ""


OBS_WS_PASSWORD = load_obs_ws_password()

EXIT_HEALTHY = 0
EXIT_ERROR = 1
EXIT_DEAD = 2
EXIT_PLUGIN_MISSING = 3
EXIT_SOURCE_MISSING = 4
EXIT_REFUSED = 5


class WebSocket:
    def __init__(self):
        self.sock = None

    def connect(self, host, port):
        sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        sock.settimeout(5)
        sock.connect((host, port))
        self.sock = sock

        key = base64.b64encode(os.urandom(16)).decode()
        upgrade = (
            f"GET / HTTP/1.1\r\n"
            f"Host: {host}:{port}\r\n"
            f"Upgrade: websocket\r\n"
            f"Connection: Upgrade\r\n"
            f"Sec-WebSocket-Key: {key}\r\n"
            f"Sec-WebSocket-Version: 13\r\n"
            f"Sec-WebSocket-Protocol: obswebsocket.json\r\n"
            f"\r\n"
        )
        sock.sendall(upgrade.encode())

        response = b""
        while b"\r\n\r\n" not in response:
            chunk = sock.recv(4096)
            if not chunk:
                raise ConnectionError("Handshake failed")
            response += chunk

        expected = base64.b64encode(
            hashlib.sha1((key + "258EAFA5-E914-47DA-95CA-C5AB0DC85B11").encode()).digest()
        ).decode()
        headers, _, _ = response.partition(b"\r\n\r\n")
        if expected not in headers.decode(errors="replace"):
            raise ConnectionError("WebSocket handshake failed")

    def send(self, data):
        payload = json.dumps(data).encode()
        frame = bytearray()
        frame.append(0x81)
        length = len(payload)
        if length < 126:
            frame.append(0x80 | length)
        elif length < 65536:
            frame.append(0x80 | 126)
            frame.extend(struct.pack(">H", length))
        else:
            frame.append(0x80 | 127)
            frame.extend(struct.pack(">Q", length))
        mask = os.urandom(4)
        frame.extend(mask)
        frame.extend(bytes(b ^ mask[i % 4] for i, b in enumerate(payload)))
        self.sock.sendall(bytes(frame))

    def recv(self):
        header = self._recv_exact(2)
        opcode = header[0] & 0x0F
        masked = (header[1] & 0x80) != 0
        length = header[1] & 0x7F
        if length == 126:
            length = struct.unpack(">H", self._recv_exact(2))[0]
        elif length == 127:
            length = struct.unpack(">Q", self._recv_exact(8))[0]
        if masked:
            mask = self._recv_exact(4)
            payload = bytes(b ^ mask[i % 4] for i, b in enumerate(self._recv_exact(length)))
        else:
            payload = self._recv_exact(length)
        if opcode == 0x8:
            return None
        if opcode == 0x9:
            self._send_pong(payload)
            return self.recv()
        return json.loads(payload.decode() if isinstance(payload, bytes) else payload)

    def _send_pong(self, payload):
        frame = bytearray()
        frame.append(0x8A)
        frame.append(len(payload))
        frame.extend(payload)
        self.sock.sendall(bytes(frame))

    def _recv_exact(self, n):
        data = b""
        while len(data) < n:
            chunk = self.sock.recv(n - len(data))
            if not chunk:
                raise ConnectionError("Connection closed")
            data += chunk
        return data

    def close(self):
        if self.sock:
            self.sock.close()


def sha256(s):
    return hashlib.sha256(s.encode()).digest()


def pipewire_obs_node_running():
    """Return True if OBS's screencast node is running in PipeWire, False if
    absent, or None if pw-dump is unavailable (probe unknown)."""
    try:
        out = subprocess.run(["pw-dump"], capture_output=True, timeout=10).stdout
        data = json.loads(out)
    except Exception:
        return None
    for o in data:
        if o.get("type") == "PipeWire:Interface:Node":
            props = o.get("info", {}).get("props", {})
            if props.get("node.name") == "obs":
                return o["info"]["state"] == "running"
    return False


def check_obs_capture():
    ws = WebSocket()
    try:
        ws.connect(OBS_WS_HOST, OBS_WS_PORT)

        hello = ws.recv()
        if hello is None or hello.get("op") != 0:
            print("Failed to receive Hello")
            return EXIT_ERROR

        challenge = hello.get("d", {}).get("authentication", {}).get("challenge", "")
        salt = hello.get("d", {}).get("authentication", {}).get("salt", "")
        auth_payload = ""
        if challenge:
            secret = base64.b64encode(sha256(OBS_WS_PASSWORD + salt)).decode()
            auth_payload = base64.b64encode(sha256(secret + challenge)).decode()

        ws.send({"op": 1, "d": {"rpcVersion": 1, "authentication": auth_payload}})
        identified = ws.recv()
        if identified is None or identified.get("op") != 2:
            print("Authentication failed")
            return EXIT_ERROR

        req_id = 0

        def send_request(req_type, req_data=None):
            nonlocal req_id
            req_id += 1
            ws.send({
                "op": 6,
                "d": {
                    "requestType": req_type,
                    "requestId": str(req_id),
                    "requestData": req_data or {},
                },
            })
            while True:
                resp = ws.recv()
                if resp is None:
                    return {}, None
                d = resp.get("d", {})
                if resp.get("op") == 7 and d.get("requestId") == str(req_id):
                    return d, d.get("requestStatus", {}).get("code")

        # Refuse to suggest a restart while streaming/recording.
        rec, _ = send_request("GetRecordStatus")
        busy = bool(rec.get("responseData", {}).get("recordingActive", False))
        if not busy:
            stream, _ = send_request("GetStreamStatus")
            busy = bool(stream.get("responseData", {}).get("outputActive", False))

        kinds, _ = send_request("GetInputKindList")
        registered = set(kinds.get("responseData", {}).get("inputKinds", []))
        if PIPE_KIND not in registered:
            print(f"{PIPE_KIND} kind not registered (OBS started before the portal/plugin was ready)")
            return EXIT_REFUSED if busy else EXIT_PLUGIN_MISSING

        inputs, _ = send_request("GetInputList")
        target = None
        for inp in inputs.get("responseData", {}).get("inputs", []):
            if inp.get("inputName") == SOURCE_NAME or inp.get("inputKind") == PIPE_KIND:
                target = inp
                break

        if not target:
            print(f"Capture source '{SOURCE_NAME}' not found")
            return EXIT_REFUSED if busy else EXIT_SOURCE_MISSING

        uuid = target.get("inputUuid", "")

        # A healthy capture has a running 'obs' node in PipeWire. When the
        # screencast session is dead the node disappears; the screenshot probe
        # alone is unreliable because OBS keeps rendering a stale cached frame.
        dead = True
        for _ in range(3):
            node_ok = pipewire_obs_node_running()
            if node_ok is None:
                shot, code = send_request(
                    "GetSourceScreenshot",
                    {"sourceUuid": uuid, "imageFormat": "png", "width": 320, "height": 180},
                )
                if code == 100 and shot.get("responseData", {}).get("imageData"):
                    node_ok = True
            if node_ok:
                dead = False
                break
            time.sleep(1)

        if dead:
            print("Capture source is not rendering (PipeWire session dead); OBS restart needed")
            return EXIT_REFUSED if busy else EXIT_DEAD

        print("Capture source is healthy")
        return EXIT_HEALTHY

    except Exception as e:
        print(f"Error: {e}")
        return EXIT_ERROR
    finally:
        ws.close()


if __name__ == "__main__":
    sys.exit(check_obs_capture())
