# Tools

Repository helper scripts live in `tools/`:

| Script | Purpose |
|---|---|
| `tools/scan-secrets.sh` | Scans the working tree for credentials / personal data (passwords, API keys, browser DBs, `Cookies`, personal home paths). Run before committing — exit 1 flags anything suspicious. |
| `tools/deploy-dotfiles.sh` | Quick re-sync: deploys only Phase 6 (dotfiles) with auto-backup, without reinstalling. Replaces existing configs in place (true mirror — safe to re-run anytime). Use after editing configs in the repo. |
| `tools/regenerate-package-lists.sh` | Re-export `packages/*.txt` from the current machine (`pacman -Qqe` + `yay -Qqm` + `flatpak`) so the repo always mirrors exactly what is installed. Run it after adding/removing packages. |
| `tools/install-calendar.sh` | Guided setup + OAuth tutorial for the [Google Calendar & birthdays sync](CALENDAR.md). |
