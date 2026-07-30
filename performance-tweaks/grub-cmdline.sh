#!/bin/bash
# Add performance kernel parameters to GRUB cmdline
# Must be run as root

GRUB_CONFIG="/etc/default/grub"

if [[ ! -f "$GRUB_CONFIG" ]]; then
    echo "GRUB config not found at $GRUB_CONFIG"
    exit 1
fi

# Backup
cp "$GRUB_CONFIG" "${GRUB_CONFIG}.bak"

# Add cstate limits for lower CPU wakeup latency
if grep -q "GRUB_CMDLINE_LINUX_DEFAULT" "$GRUB_CONFIG"; then
    sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="\(.*\)"/GRUB_CMDLINE_LINUX_DEFAULT="\1 processor.max_cstate=1 intel_idle.max_cstate=1"/' "$GRUB_CONFIG"
fi

# Regenerate GRUB config
grub-mkconfig -o /boot/grub/grub.cfg

echo "GRUB updated with performance kernel parameters."
