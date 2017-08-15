#!/bin/bash

exec 0<&- # close stdin

set -e -u -o pipefail

## kernel is replaced with kernel-ml when installing the mainline kernel
old_kernel_pkg=""
kernel_pkg=""
if rpm -q kernel ; then
    old_kernel_pkg=$( rpm -q kernel )
fi

## upgrade everything so we're always up to date
yum upgrade -y

if rpm -q kernel ; then
    kernel_pkg=$( rpm -q kernel )
fi

if [ -n "${old_kernel_pkg}" ] && [ "$( rpm -q kernel | wc -l )" -gt 1 ]; then
    rpm -e "${old_kernel_pkg}"

    echo "Running kernel ${old_kernel_pkg} not new kernel ${kernel_pkg} so rebooting"
    systemctl reboot
    sleep 240
fi
