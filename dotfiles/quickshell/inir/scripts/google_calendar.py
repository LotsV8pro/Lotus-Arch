#!/usr/bin/env python3
"""Google Calendar OAuth (device flow) + sync helpers for the shell.

Commands (all JSON on stdout, errors JSON on stderr):
  oauth-request <client_id>                    -> {verification_url,user_code,device_code,interval,expires_in,client_id}
  oauth-poll <client_id> <client_secret> <device_code> <token_path>
                                               -> {status:"ok",access_token,...} token also saved to token_path
                                               -> {status:"pending"} | {status:"error",error}
  token-info <token_path>                      -> {email,expiry} or error
  list-calendars <token_path>                  -> {calendars:[{id,summary,accessRole}]}
  import <token_path> <calendar_id> <days>     -> {events:[...]} events resolved single, allday-aware
  create-event <token_path> <json>             -> {event:{id,htmlLink}}
  refresh <token_path>                         -> writes new access token, {ok:true}
"""
import json
import os
import sys
import time
import urllib.error
import urllib.parse
import urllib.request

SCOPES = "https://www.googleapis.com/auth/calendar"


def read_token(path):
    if not os.path.exists(path):
        return None
    with open(path) as f:
        return json.load(f)


def write_token(path, data):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    tmp = path + ".tmp"
    with open(tmp, "w") as f:
        json.dump(data, f, indent=2)
    os.replace(tmp, path)


def http_json(url, data=None, headers=None, method=None, timeout=30):
    body = None
    hdrs = dict(headers or {})
    if data is not None:
        if isinstance(data, dict):
            body = urllib.parse.urlencode(data).encode()
            hdrs.setdefault("Content-Type", "application/x-www-form-urlencoded")
        else:
            body = data
            hdrs.setdefault("Content-Type", "application/json")
    req = urllib.request.Request(url, data=body, headers=hdrs, method=method)
    try:
        with urllib.request.urlopen(req, timeout=timeout) as resp:
            raw = resp.read()
            return json.loads(raw) if raw.strip() else {}
    except urllib.error.HTTPError as e:
        raw = e.read()
        try:
            info = json.loads(raw) if raw else {}
        except Exception:
            info = {"error": raw.decode(errors="replace")[:500]}
        info["_http_code"] = e.code
        raise GoogleApiError(json.dumps(info))


class GoogleApiError(Exception):
    pass


def api(path, token_path, **kwargs):
    tok = read_token(token_path)
    if not tok or not tok.get("access_token"):
        raise GoogleApiError(json.dumps({"error": "no_token"}))
    hdrs = {"Authorization": "Bearer " + tok["access_token"]}
    try:
        return http_json("https://www.googleapis.com/calendar/v3" + path, headers=hdrs, **kwargs)
    except GoogleApiError as e:
        info = json.loads(str(e))
        if info.get("_http_code") in (401, 403) and tok.get("refresh_token"):
            refresh_token(token_path)
            tok = read_token(token_path)
            hdrs = {"Authorization": "Bearer " + tok["access_token"]}
            return http_json("https://www.googleapis.com/calendar/v3" + path, headers=hdrs, **kwargs)
        raise


def refresh_token(token_path):
    tok = read_token(token_path)
    if not tok or not tok.get("refresh_token"):
        raise GoogleApiError(json.dumps({"error": "no_refresh_token"}))
    res = http_json("https://oauth2.googleapis.com/token", data={
        "client_id": tok["client_id"],
        "client_secret": tok.get("client_secret", ""),
        "refresh_token": tok["refresh_token"],
        "grant_type": "refresh_token",
    })
    tok["access_token"] = res["access_token"]
    if "expires_in" in res:
        tok["expires_in"] = res["expires_in"]
        tok["expiry"] = time.time() + res["expires_in"]
    write_token(token_path, tok)
    return tok


# ── Device flow ──────────────────────────────────────────────────────────────

def oauth_request(client_id):
    res = http_json("https://oauth2.googleapis.com/device/code", data={
        "client_id": client_id, "scope": SCOPES,
    })
    res["client_id"] = client_id
    print(json.dumps(res))


def oauth_poll(client_id, client_secret, device_code, token_path):
    try:
        res = http_json("https://oauth2.googleapis.com/token", data={
            "client_id": client_id,
            "client_secret": client_secret or None,
            "device_code": device_code,
            "grant_type": "urn:ietf:params:oauth:grant_type:device_code",
        })
        tok = {
            "client_id": client_id,
            "client_secret": client_secret or "",
            "access_token": res["access_token"],
            "refresh_token": res.get("refresh_token", ""),
            "expires_in": res.get("expires_in", 3600),
            "expiry": time.time() + res.get("expires_in", 3600),
        }
        write_token(token_path, tok)
        res["status"] = "ok"
        print(json.dumps(res))
    except GoogleApiError as e:
        info = json.loads(str(e))
        if info.get("error") in ("authorization_pending", "slow_down"):
            print(json.dumps({"status": "pending"}))
        else:
            print(json.dumps({"status": "error", "error": info.get("error", "unknown")}))


# ── Introspection ────────────────────────────────────────────────────────────

def cmd_token_info(token_path):
    tok = read_token(token_path)
    if not tok or not tok.get("access_token"):
        print(json.dumps({"error": "no_token", "path": token_path}))
        return
    try:
        info = http_json("https://www.googleapis.com/oauth2/v2/userinfo",
                         headers={"Authorization": "Bearer " + tok["access_token"]})
        print(json.dumps({"email": info.get("email", ""), "name": info.get("name", ""),
                          "picture": info.get("picture", "")}))
    except GoogleApiError:
        print(json.dumps({"error": "token_invalid", "path": token_path}))


def cmd_list_calendars(token_path):
    res = api("users/me/calendarList", token_path)
    out = []
    for cal in res.get("items", []):
        out.append({
            "id": cal["id"],
            "summary": cal["summary"],
            "accessRole": cal.get("accessRole", "reader"),
            "backgroundColor": cal.get("backgroundColor", "#4285F4"),
        })
    out.sort(key=lambda c: c["summary"].lower())
    print(json.dumps({"calendars": out}))


def cmd_import(token_path, calendar_id, days):
    time_min = time.strftime("%Y-%m-%dT00:00:00Z", time.gmtime(time.time()))
    time_max = time.strftime("%Y-%m-%dT00:00:00Z", time.gmtime(time.time() + int(days) * 86400))
    params = ("singleEvents=true&orderBy=startTime&maxResults=2500"
              "&timeMin=" + urllib.parse.quote(time_min) + "&timeMax=" + urllib.parse.quote(time_max))
    res = api("/calendars/" + urllib.parse.quote(calendar_id, safe="") + "/events?" + params, token_path)
    events = []
    for ev in res.get("items", []):
        start = ev.get("start", {})
        end = ev.get("end", {})
        all_day = "date" in start
        start_val = start.get("date") or start.get("dateTime")
        end_val = end.get("date") or end.get("dateTime")
        recurrence = "none"
        if ev.get("recurringEventId") or ev.get("recurrence"):
            recurrence = "recurring"
        events.append({
            "uid": ev.get("id", ""),
            "title": ev.get("summary", "(No title)"),
            "description": ev.get("description", ""),
            "location": ev.get("location", ""),
            "start": start_val,
            "end": end_val or start_val,
            "allDay": all_day,
            "recurrence": recurrence,
            "eventId": ev.get("id", ""),
        })
    print(json.dumps({"events": events}))


def cmd_create_event(token_path, payload):
    body = {
        "summary": payload.get("title", "(No title)"),
        "description": payload.get("description", ""),
        "location": payload.get("location", ""),
    }
    if payload.get("allDay"):
        d = payload["start"][:10]
        body["start"] = {"date": d}
        end_d = payload.get("end", payload["start"])[:10]
        body["end"] = {"date": end_d or d}
    else:
        body["start"] = {"dateTime": payload["start"]}
        body["end"] = {"dateTime": payload.get("end") or payload["start"]}
    res = api("/calendars/primary/events", token_path, data=json.dumps(body), method="POST")
    print(json.dumps({"event": {"id": res.get("id", ""), "htmlLink": res.get("htmlLink", "")}}))


# ── Dispatcher ───────────────────────────────────────────────────────────────

def main():
    cmd = sys.argv[1] if len(sys.argv) > 1 else ""
    try:
        if cmd == "oauth-request":
            oauth_request(sys.argv[2])
        elif cmd == "oauth-poll":
            oauth_poll(sys.argv[2], sys.argv[3], sys.argv[4], sys.argv[5])
        elif cmd == "token-info":
            cmd_token_info(sys.argv[2])
        elif cmd == "refresh":
            refresh_token(sys.argv[2])
            print(json.dumps({"ok": True}))
        elif cmd == "list-calendars":
            cmd_list_calendars(sys.argv[2])
        elif cmd == "import":
            cmd_import(sys.argv[2], sys.argv[3], int(sys.argv[4]) if len(sys.argv) > 4 else 365)
        elif cmd == "create-event":
            payload = json.loads(sys.argv[3])
            cmd_create_event(sys.argv[2], payload)
        else:
            print(json.dumps({"error": "unknown_command", "usage": __doc__}), file=sys.stderr)
            sys.exit(2)
    except GoogleApiError as e:
        print(json.dumps({"error": str(e)}), file=sys.stderr)
        sys.exit(1)
    except Exception as e:
        print(json.dumps({"error": str(e)}), file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()