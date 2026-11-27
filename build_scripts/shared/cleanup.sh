#!/usr/bin/bash
set -Eeuo pipefail

source /ctx/build_scripts/lib/common.sh
require_root
log_group "$(basename "$0")"

# Undo build-only DNF tuning from build-prep.sh.
if [ -f /etc/dnf/dnf.conf.bak ]; then
    mv /etc/dnf/dnf.conf.bak /etc/dnf/dnf.conf
fi

# Remove known build residue. This RUN has no cache mount, so /var/cache/*
# is committed residue, not the live libdnf5 cache.
rm -rf \
    /var/log/dnf5.log* \
    /var/lib/dnf \
    /var/lib/flatpak/repo/tmp \
    /usr/lib/sysimage/libdnf5/* \
    /var/cache/*

# Podman/Buildah supplies runtime-only paths under /run. Never touch
# /run/systemd* (buildah DNS bind mounts) or /run/secrets (secret mounts).
find /run -mindepth 1 \
    ! -path '/run/systemd*' \
    ! -path '/run/secrets' \
    ! -path '/run/secrets/*' \
    ! -name '.containerenv' \
    -delete

# Normalize mtimes so chunkah sees the same bytes for unchanged files on every
# build. Files created at build time otherwise get a fresh mtime, which forces
# their layers to be re-downloaded even when their content did not change.
# -h stamps the symlink itself instead of following it; epoch+1 avoids
# zero-timestamp edge cases. (Aurora unpackaged.sh; chunkah issue #160.)
for dir in /usr /etc /opt; do
    [ -d "$dir" ] || continue
    find "$dir" -newermt '1970-01-01T00:00:00Z' \
        -exec touch -h -a -m -d '1970-01-01T00:00:01Z' {} +
done

# /tmp must be empty for bootc lint; clear dotfiles too.
rm -rf /tmp/* /tmp/.[!.]* /tmp/..?*
mkdir -p /var/tmp /var/cache

log_group_end