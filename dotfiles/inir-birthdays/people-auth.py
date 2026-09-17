#!/usr/bin/env python3
"""Re-authorize the gcalcli OAuth token, adding the People/Contacts scope.

The existing token at ~/.local/share/gcalcli/oauth only holds the `calendar`
scope. To write birthdays to Google's built-in "Cumpleaños" calendar we must
edit a Google Contact's birthday field, which needs the People API
(https://www.googleapis.com/auth/contacts).

This script re-runs the OAuth consent flow with BOTH scopes using the same
OAuth client id/secret already stored in the existing token, so the new token
powers both the calendar mirror (gcal-op.py) and the birthday contact writes.

It prints an authorization URL; open it in a browser, approve, then paste the
resulting code back here. The refreshed token is saved atomically over the
gcalcli oauth file (a backup is kept at oauth.people-bak).

Usage:
  python3 ~/.config/inir-birthdays/people-auth.py
"""

import os
import pickle
import socket
import sys
import urllib.parse
import webbrowser

from google.auth.transport.requests import Request
from google_auth_oauthlib.flow import Flow

OAUTH_FILE = os.path.expanduser("~/.local/share/gcalcli/oauth")
BACKUP = os.path.expanduser("~/.local/share/gcalcli/oauth.people-bak")
TOKEN_URI = "https://oauth2.googleapis.com/token"
AUTH_URI = "https://accounts.google.com/o/oauth2/auth"

SCOPES = [
    "https://www.googleapis.com/auth/calendar",
    "https://www.googleapis.com/auth/contacts",
]

REDIRECT_PORT = 8412
REDIRECT_URI = f"http://localhost:{REDIRECT_PORT}"


def main():
    creds = None
    if os.path.exists(OAUTH_FILE):
        with open(OAUTH_FILE, "rb") as fh:
            creds = pickle.load(fh)
        client_id = creds.client_id
        client_secret = creds.client_secret
        if not client_id or not client_secret:
            print("Stored token has no client_id/secret; aborting.")
            return 1
    else:
        print("No existing oauth token found at", OAUTH_FILE)
        return 1

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

    auth_url, _ = flow.authorization_url(
        access_type="offline",
        include_granted_scopes="true",
        prompt="consent",
    )

    print("Open this URL in your browser and authorize:")
    print(auth_url)
    print()
    try:
        webbrowser.open(auth_url)
    except Exception:
        pass

    code = input("Paste the full redirect URL you land on (or just the code): ").strip()
    # Accept either the whole URL or the bare code param.
    if "code=" in code:
        qs = urllib.parse.parse_qs(urllib.parse.urlparse(code).query)
        code = qs["code"][0]

    flow.fetch_token(code=code)

    new_creds = flow.credentials
    new_creds.token_uri = TOKEN_URI
    # Reuse the same client identifiers the rest of the stack expects.
    try:
        os.replace(OAUTH_FILE, BACKUP)
    except OSError:
        pass
    with open(OAUTH_FILE, "wb") as fh:
        pickle.dump(new_creds, fh)

    print()
    print("Saved new token to", OAUTH_FILE)
    print("Scopes:", new_creds.scopes)
    print("Backup of previous token: ", BACKUP)
    return 0


if __name__ == "__main__":
    sys.exit(main())