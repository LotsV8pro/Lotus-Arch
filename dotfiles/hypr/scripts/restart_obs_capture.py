#!/usr/bin/env python3
"""
Restart OBS PipeWire screen capture source via obs-websocket.
Uses only built-in Python modules (socket, ssl, json, hashlib, base64, struct).
"""
import socket
import ssl
import json
import hashlib
import base64
import struct
import os
import sys
import time

OBS_WS_HOST = "127.0.0.1"
OBS_WS_PORT = 4455
OBS_WS_PASSWORD = "***REMOVED***"
SOURCE_NAME = "Screen Capture (PipeWire)"


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
        if expected not in response.decode():
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


def restart_obs_capture():
    ws = WebSocket()
    try:
        ws.connect(OBS_WS_HOST, OBS_WS_PORT)

        hello = ws.recv()
        if hello is None or hello.get("op") != 0:
            print("Failed to receive Hello")
            return False

        challenge = hello.get("d", {}).get("authentication", {}).get("challenge", "")
        salt = hello.get("d", {}).get("authentication", {}).get("salt", "")
        if challenge:
            secret = base64.b64encode(sha256(OBS_WS_PASSWORD + salt)).decode()
            auth_payload = base64.b64encode(sha256(secret + challenge)).decode()
        else:
            auth_payload = ""

        identify = {
            "op": 1,
            "d": {
                "rpcVersion": 1,
            }
        }
        if auth_payload:
            identify["d"]["authentication"] = auth_payload
        ws.send(identify)

        identified = ws.recv()
        if identified is None or identified.get("op") != 2:
            print("Authentication failed")
            return False

        req_id = 0

        def send_request(req_type, req_data=None):
            nonlocal req_id
            req_id += 1
            msg = {
                "op": 6,
                "d": {
                    "requestType": req_type,
                    "requestId": str(req_id),
                    "requestData": req_data or {}
                }
            }
            ws.send(msg)
            resp = ws.recv()
            return resp.get("d", {}) if resp else {}

        sources_resp = send_request("GetInputList")
        inputs = sources_resp.get("responseData", {}).get("inputs", [])
        target = None
        for inp in inputs:
            if inp.get("inputName") == SOURCE_NAME or "PipeWire" in inp.get("inputName", "") or "pipewire" in inp.get("inputKind", ""):
                target = inp
                break

        if not target:
            for inp in inputs:
                if "pipewire" in inp.get("inputKind", "").lower():
                    target = inp
                    break

        if not target:
            print(f"Source '{SOURCE_NAME}' not found")
            return False

        uuid = target.get("inputUuid") or target.get("inputName")
        kind = target.get("inputKind", "")

        input_name = target["inputName"]
        input_uuid = target.get("inputUuid", input_name)

        settings_resp = send_request("GetInputSettings", {"inputUuid": input_uuid})
        settings = settings_resp.get("responseData", {}).get("inputSettings", {})

        if not settings:
            settings = {}

        kind = target.get("inputKind", "")

        scene_resp = send_request("GetCurrentProgramScene")
        scene_uuid = scene_resp.get("responseData", {}).get("currentProgramSceneUuid", "")

        items_resp = send_request("GetSceneItemList", {"sceneUuid": scene_uuid})
        items = items_resp.get("responseData", {}).get("sceneItems", [])

        item = None
        for i in items:
            if i.get("sourceUuid") == input_uuid or i.get("sourceName") == input_name:
                item = i
                break

        old_item_id = item.get("sceneItemId", 0) if item else None
        old_transform = item.get("transform", {}) if item else {}

        if old_item_id:
            send_request("RemoveSceneItem", {
                "sceneUuid": scene_uuid,
                "sceneItemId": old_item_id
            })

        send_request("RemoveInput", {
            "inputUuid": input_uuid
        })

        time.sleep(0.5)

        create_resp = send_request("CreateInput", {
            "sceneUuid": scene_uuid,
            "inputName": input_name,
            "inputKind": kind,
            "inputSettings": settings,
            "sceneItemEnabled": True
        })

        new_uuid = create_resp.get("responseData", {}).get("inputUuid", "")

        if old_transform and new_uuid:
            items2_resp = send_request("GetSceneItemList", {"sceneUuid": scene_uuid})
            for i2 in items2_resp.get("responseData", {}).get("sceneItems", []):
                if i2.get("sourceUuid") == new_uuid:
                    send_request("SetSceneItemTransform", {
                        "sceneUuid": scene_uuid,
                        "sceneItemId": i2["sceneItemId"],
                        "transform": old_transform
                    })
                    break

        print(f"Restarted capture source: {input_name}")
        return True

    except Exception as e:
        print(f"Error: {e}")
        return False
    finally:
        ws.close()


if __name__ == "__main__":
    success = restart_obs_capture()
    sys.exit(0 if success else 1)
