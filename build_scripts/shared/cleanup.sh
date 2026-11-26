#!/usr/bin/bash
set -Eeuo pipefail

source /ctx/build_scripts/lib/common.sh
require_root
log_group "$(basename "$0")"

# Remove known build residue. This RUN has no cache mount, so /var/cache/*
# is committed residue, not the live libdnf5 cache.
rm -rf \
    /var/log/dnf5.log* \
    /var/lib/dnf \
    /var/lib/flatpak/repo/tmp \
    /var/cache/*

# Podman/Buildah supplies runtime-only paths under /run. Never touch
# /run/systemd* (buildah DNS bind mounts) or /run/secrets (secret mounts).
find /run -mindepth 1 \
    ! -path '/run/systemd*' \
    ! -path '/run/secrets' \
    ! -path '/run/secrets/*' \
    ! -name '.containerenv' \
    -exec rm -rf {} +

# /tmp must be empty for bootc lint; clear dotfiles too.
rm -rf /tmp/* /tmp/.[!.]* /tmp/..?*
mkdir -p /var/tmp /var/cache

log_group_end