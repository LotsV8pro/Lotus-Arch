#!/usr/bin/env bash

# Library file: intended to be sourced by other scripts.
# Do not set shell options here; callers own execution mode.

# Canonical iNiR config directory is ~/.config/inir.
# Legacy installs used ~/.config/illogical-impulse.
#
# Compatibility policy (inir is the canonical/home shell config):
# - If new dir exists, use it (even if a real legacy dir also exists).
# - Real legacy dir only used when new one is absent.
# - If none exists, default to new dir.

XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"

INIR_CONFIG_DIR_NEW="${XDG_CONFIG_HOME}/inir"
INIR_CONFIG_DIR_OLD="${XDG_CONFIG_HOME}/illogical-impulse"

inir_config_dir() {
    # Canonical new path wins when it exists (inir is the primary shell config).
    if [[ -d "$INIR_CONFIG_DIR_NEW" ]]; then
        printf '%s\n' "$INIR_CONFIG_DIR_NEW"
        return
    fi

    # Legacy real directory only when the new one is absent.
    if [[ -d "$INIR_CONFIG_DIR_OLD" ]]; then
        printf '%s\n' "$INIR_CONFIG_DIR_OLD"
        return
    fi

    # Fresh install default.
    printf '%s\n' "$INIR_CONFIG_DIR_NEW"
}

inir_config_file() {
    printf '%s/config.json\n' "$(inir_config_dir)"
}

inir_version_file() {
    printf '%s/version.json\n' "$(inir_config_dir)"
}

inir_installed_marker_file() {
    printf '%s/installed_true\n' "$(inir_config_dir)"
}

inir_migrations_state_file() {
    printf '%s/migrations.json\n' "$(inir_config_dir)"
}
