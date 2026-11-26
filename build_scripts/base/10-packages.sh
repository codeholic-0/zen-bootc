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
    mediawriter \
    gthumb \
    yt-dlp \
    vlc \
    zenity \
    kate \
    guvcview \
    docker-ce \
    docker-compose-plugin \
    docker-buildx-plugin \
    podman \
    podman-compose \
    flatpak \
    fedora-flathub-remote \
    fedora-workstation-repositories \
    fedora-third-party \
    udisks2-btrfs \
    libblockdev-btrfs \
    cryfs \
    earlyoom \
    cronie \
    cronie-anacron \
    crontabs \
    lm_sensors \
    zsh \
    git \
    curl \
    wget2 \
    wget2-wget \
    jq \
    distrobox \
    btop \
    fastfetch \
    plocate \
    bat \
    eza \
    fd-find \
    fzf \
    ripgrep \
    zoxide \
    dos2unix \
    smem \
    scrub

log_group_end