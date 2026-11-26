#!/usr/bin/bash
set -Eeuo pipefail

source /ctx/build_scripts/lib/common.sh
require_root
log_group "$(basename "$0")"

test "$(readlink /etc/os-release)" = "../usr/lib/os-release"

systemctl is-enabled NetworkManager.service >/dev/null
systemctl is-enabled plasmalogin.service >/dev/null
systemctl is-enabled docker.service >/dev/null
systemctl is-enabled earlyoom.service >/dev/null
systemctl is-enabled crond.service >/dev/null

flatpak remote-list --system | grep -q flathub

bootc container lint

log_group_end