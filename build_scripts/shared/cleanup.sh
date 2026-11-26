#!/usr/bin/bash
set -Eeuo pipefail

source /ctx/build_scripts/lib/common.sh
require_root
log_group "$(basename "$0")"

# Remove known build residue without clearing package cache mounts.
rm -rf \
    /var/log/dnf5.log* \
    /var/lib/dnf \
    /var/lib/flatpak/repo/tmp

# Podman/Buildah supplies runtime-only paths under /run.
find /run -mindepth 1 \
    ! -path '/run/systemd*' \
    ! -name '.containerenv' \
    -delete

rm -rf /tmp/*
mkdir -p /var/tmp /var/cache

log_group_end