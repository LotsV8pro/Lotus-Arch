#!/usr/bin/env python3
"""Re-autenticación Google Calendar (calendar + contacts) usando el client_id
guardado en ~/.local/share/gcalcli/oauth.

Modo 1: genera (o reusa) una URL de autorización y la guarda en
         ~/.cache/gcal-auth-url.txt
Modo 2: completa el flujo con el código pegado y escribe el nuevo token.

Uso:
  gcal_reauth.py url          -> imprime y guarda la URL de autorización
  gcal_reauth.py code <CODE>  -> canjea el código y guarda el token nuevo
"""

import os
import pickle
import sys
import urllib.parse

from google.auth.transport.requests import Request
from google_auth_oauthlib.flow import Flow

OAUTH_FILE = os.path.expanduser("~/.local/share/gcalcli/oauth")
URL_FILE = os.path.expanduser("~/.cache/gcal-auth-url.txt")
FLOW_STATE = os.path.expanduser("~/.cache/gcal-flow-state.pkl")
TOKEN_URI = "https://oauth2.googleapis.com/token"
AUTH_URI = "https://accounts.google.com/o/oauth2/auth"
SCOPES = [
    "https://www.googleapis.com/auth/calendar",
    "https://www.googleapis.com/auth/contacts",
]
REDIRECT_URI = "http://localhost:8412"


def load_client():
    with open(OAUTH_FILE, "rb") as fh:
        creds = pickle.load(fh)
    return creds.client_id, creds.client_secret


def make_flow(client_id, client_secret):
    flow = Flow.from_client_config(
        {
            "installed": {
                "client_id": client_id,
                "client_secret": client_secret,
                "auth_uri": AUTH_URI,
                "token_uri": TOKEN_URI,
                "redirect_uris": [REDIRECT_URI],
            }
        },
        scopes=SCOPES,
    )
    flow.redirect_uri = REDIRECT_URI
    return flow


def save_flow(flow):
    state = {
        "code_verifier": flow.code_verifier,
        "client_config": flow.client_config,
    }
    with open(FLOW_STATE, "wb") as fh:
        pickle.dump(state, fh)


def load_flow_state():
    with open(FLOW_STATE, "rb") as fh:
        return pickle.load(fh)


def cmd_url():
    client_id, client_secret = load_client()
    flow = make_flow(client_id, client_secret)
    auth_url, _ = flow.authorization_url(
        access_type="offline", include_granted_scopes="true", prompt="select_account"
    )
    save_flow(flow)
    with open(URL_FILE, "w", encoding="utf-8") as fh:
        fh.write(auth_url)
    print(auth_url)
    return 0


def cmd_code(code):
    if "code=" in code:
        qs = urllib.parse.parse_qs(urllib.parse.urlparse(code).query)
        code = qs["code"][0]
    flow_state = load_flow_state()
    flow = Flow.from_client_config(
        {"installed": flow_state["client_config"]},
        scopes=SCOPES,
    )
    flow.redirect_uri = REDIRECT_URI
    flow.code_verifier = flow_state["code_verifier"]
    flow.fetch_token(code=code)
    creds = flow.credentials
    os.replace(OAUTH_FILE, OAUTH_FILE + ".bak3")
    with open(OAUTH_FILE, "wb") as fh:
        pickle.dump(creds, fh)
    os.unlink(FLOW_STATE)
    print("OK scopes:", creds.scopes)
    return 0


if __name__ == "__main__":
    sys.exit(cmd_url() if len(sys.argv) < 2 or sys.argv[1] == "url" else cmd_code(sys.argv[2]))