#!/usr/bin/env bash
# Automatically unmask and force-start the required portals
systemctl --user unmask xdg-desktop-portal-gtk
systemctl --user restart xdg-desktop-portal-gtk xdg-desktop-portal pipewire wireplumber
