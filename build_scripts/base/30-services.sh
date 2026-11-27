#!/usr/bin/bash
set -Eeuo pipefail

source /ctx/build_scripts/lib/common.sh
require_root
log_group "$(basename "$0")"

flatpak remote-add --if-not-exists --system \
    flathub https://dl.flathub.org/repo/flathub.flatpakrepo

flatpak remote-modify --system --enable flathub

systemctl enable \
    NetworkManager.service \
    plasmalogin.service \
    docker.service \
    earlyoom.service \
    crond.service \
    bootc-update-ca-trust.service \
    bootc-update-crypto-policies.service \
    -f
systemctl disable NetworkManager-wait-online.service -f
systemctl mask NetworkManager-wait-online.service -f

log_group_end