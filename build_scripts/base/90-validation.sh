#!/usr/bin/bash
set -Eeuo pipefail

source /ctx/build_scripts/lib/common.sh
require_root
log_group "$(basename "$0")"

test "$(readlink /etc/os-release)" = "../usr/lib/os-release"

for pkg in docker-ce podman flatpak distrobox kate vlc zsh jq curl bootc ffmpeg; do
    rpm -q "$pkg" >/dev/null || { echo "missing package: $pkg" >&2; exit 1; }
done

for pkg in firefox plasma-discover plasma-welcome kwrite krfb akonadi-server xwaylandvideobridge ffmpeg-free; do
    if rpm -q "$pkg" >/dev/null 2>&1; then
        echo "unwanted package present: $pkg" >&2; exit 1
    fi
done

rpm -q --qf '%{VENDOR}\n' ffmpeg | grep -qi 'rpm fusion' \
    || { echo "ffmpeg is not from RPM Fusion" >&2; exit 1; }


systemctl is-enabled NetworkManager.service >/dev/null
systemctl is-enabled plasmalogin.service >/dev/null
systemctl is-enabled docker.service >/dev/null
systemctl is-enabled earlyoom.service >/dev/null
systemctl is-enabled crond.service >/dev/null

flatpak remote-list --system | grep -q flathub

bootc container lint --no-truncate

log_group_end