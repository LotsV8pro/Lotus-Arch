#!/bin/bash
# Add performance kernel parameters to GRUB cmdline
# Usage: grub-cmdline.sh [intel|amd]
#   intel  → processor.max_cstate=1 intel_idle.max_cstate=1  (default, i7-13700KF tuned)
#   amd    → processor.max_cstate=1                          (applies to AMD CPUs too)
# Must be run as root

PROFILE="${1:-intel}"

GRUB_CONFIG="/etc/default/grub"

if [[ ! -f "$GRUB_CONFIG" ]]; then
    echo "GRUB config not found at $GRUB_CONFIG"
    exit 1
fi

# Backup
cp "$GRUB_CONFIG" "${GRUB_CONFIG}.bak"

# Add cstate limits for lower CPU wakeup latency
if grep -q "GRUB_CMDLINE_LINUX_DEFAULT" "$GRUB_CONFIG"; then
    if [[ "$PROFILE" == "amd" ]]; then
        sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="\(.*\)"/GRUB_CMDLINE_LINUX_DEFAULT="\1 processor.max_cstate=1"/' "$GRUB_CONFIG"
    else
        sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="\(.*\)"/GRUB_CMDLINE_LINUX_DEFAULT="\1 processor.max_cstate=1 intel_idle.max_cstate=1"/' "$GRUB_CONFIG"
    fi
fi

# Regenerate GRUB config
grub-mkconfig -o /boot/grub/grub.cfg

echo "GRUB updated with performance kernel parameters ($PROFILE)."
