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
    plasma-systemmonitor
    kwrite
    krfb
)

dnf -y remove "${KDE_REMOVE[@]}"
dnf -y autoremove

DEV_DEPS=(
    # Compilers & build tools
    gcc
    gcc-c++
    automake
    autoconf
    make
    cmake
    lld
    python3
    python3-pip

    # Debugging
    gdb

    # Editors & IDEs
    neovim
    codium
    kate
    tmux

    # Version control
    git
    git-lfs
    gh

    # Data & scripting
    jq
    yq
    sqlite

    # Development environments
    distrobox

    # Code quality
    shellcheck
)

SHELL_UTILS=(
    # Shell
    zsh

    # Modern CLI replacements
    bat
    eza
    fd-find
    ripgrep

    # Web Fetch
    curl
    wget2

    # Search & navigation
    fzf
    zoxide

    # System monitoring
    btop
    fastfetch
    lm_sensors
    smem

    # File & text utilities
    dos2unix
    plocate
)

MEDIA=(
    # Video & audio
    vlc
    yt-dlp

    # Image management
    gthumb

    # Webcam
    guvcview
)

CONTAINERS=(
    # Docker
    docker-ce
    docker-compose-plugin
    docker-buildx-plugin

    # Podman
    podman
    podman-compose
)

SYSTEM_UTILS=(
    # Disk & filesystem
    udisks2-btrfs
    libblockdev-btrfs
    cryfs
    scrub

    # Process & resource management
    earlyoom

    # Scheduling
    cronie
    cronie-anacron
    crontabs
)

DESKTOP_APPS=(
    # Desktop utilities
    zenity
    mediawriter
)

REPOSITORIES=(
    flatpak
    fedora-flathub-remote
    fedora-workstation-repositories
    fedora-third-party
)

dnf_install \
    "${DEV_DEPS[@]}" \
    "${SHELL_UTILS[@]}" \
    "${MEDIA[@]}" \
    "${CONTAINERS[@]}" \
    "${SYSTEM_UTILS[@]}" \
    "${DESKTOP_APPS[@]}" \
    "${REPOSITORIES[@]}"

dnf -y install --exclude=gedit iverilog verilator gtkwave

log_group_end