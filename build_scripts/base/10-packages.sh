#!/usr/bin/bash
set -Eeuo pipefail

source /ctx/build_scripts/lib/common.sh
require_root
log_group "$(basename "$0")"

KDE_REMOVE=(
    akonadi-server
    akonadi-server-mysql
    fedora-bookmarks
    fedora-chromium-config
    fedora-chromium-config-kde
    firefox
    kcharselect
    khelpcenter
    plasma-discover
    plasma-welcome
    plasma-welcome-fedora
    xwaylandvideobridge
    kwrite
    krfb
)

dnf -y remove "${KDE_REMOVE[@]}"
dnf -y autoremove

dnf_install \
    gthumb yt-dlp vlc \
    zenity kate guvcview mediawriter\
    docker-ce docker-compose-plugin docker-buildx-plugin podman podman-compose \
    flatpak fedora-flathub-remote fedora-workstation-repositories fedora-third-party \
    udisks2-btrfs libblockdev-btrfs cryfs \
    earlyoom cronie cronie-anacron crontabs \
    scrub plocate\
    zsh git jq distrobox \
    btop fastfetch lm_sensors smem\
    bat eza fd-find fzf ripgrep zoxide dos2unix

log_group_end