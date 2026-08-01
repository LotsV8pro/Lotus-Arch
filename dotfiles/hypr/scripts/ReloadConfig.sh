#!/usr/bin/env bash
# Reload Hyprland config.
# NOTE: hyprctl reload does NOT break an active OBS PipeWire capture (verified),
# so we do not touch OBS here. If a capture ever does break, run
# scripts/restart_obs_capture.py manually to re-create it.

hyprctl reload
