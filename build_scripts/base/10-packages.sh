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

PLYMOUTH=(
    plymouth
    plymouth-system-theme
    plymouth-theme-breeze
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
    "${PLYMOUTH[@]}" \
    "${CONTAINERS[@]}" \
    "${SYSTEM_UTILS[@]}" \
    "${DESKTOP_APPS[@]}" \
    "${REPOSITORIES[@]}"

dnf -y install --exclude=gedit iverilog verilator gtkwave

FONT_DIR="/usr/share/fonts/nerd-fonts"

mkdir -p "$FONT_DIR"

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

curl -fL \
  "https://github.com/ryanoasis/nerd-fonts/releases/download/v3.5.1/FiraCode.zip" \
  -o "$TMP_DIR/FiraCode.zip"

curl -fL \
  "https://github.com/ryanoasis/nerd-fonts/releases/download/v3.5.1/NerdFontsSymbolsOnly.zip" \
  -o "$TMP_DIR/NerdFontsSymbolsOnly.zip"

unzip -oq "$TMP_DIR/FiraCode.zip" -d "$TMP_DIR/FiraCode"
unzip -oq "$TMP_DIR/NerdFontsSymbolsOnly.zip" -d "$TMP_DIR/Symbols"

find "$TMP_DIR/FiraCode" "$TMP_DIR/Symbols" \
  -type f \( -iname '*.ttf' -o -iname '*.otf' \) \
  -exec install -m 644 {} "$FONT_DIR/" \;

fc-cache -f "$FONT_DIR"

echo "FiraCode Nerd Font and Nerd Fonts Symbols Only installed."

log_group_end