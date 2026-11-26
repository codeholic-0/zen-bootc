#!/usr/bin/bash
set -Eeuo pipefail

source /ctx/build_scripts/lib/common.sh
require_root
log_group "$(basename "$0")"

: "${FEDORA_VER:?FEDORA_VER must be set}"

dnf install -y \
    "https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-${FEDORA_VER}.noarch.rpm" \
    "https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-${FEDORA_VER}.noarch.rpm"

dnf config-manager addrepo --overwrite \
    --from-repofile=https://download.docker.com/linux/fedora/docker-ce.repo

dnf -y copr enable imput/helium
dnf -y config-manager addrepo --from-repofile=https://repo.librewolf.net/librewolf.repo

dnf config-manager setopt \
    'rpmfusion-free.enabled=1' \
    'rpmfusion-free-updates.enabled=1' \
    'rpmfusion-nonfree.enabled=1' \
    'rpmfusion-nonfree-updates.enabled=1'

dnf config-manager setopt fedora-cisco-openh264.enabled=1

dnf install -y \
    rpmfusion-free-release-tainted \
    rpmfusion-nonfree-release-tainted

dnf makecache --refresh

# bootc-image-builder reads repositories from /etc/yum.repos.d.
if compgen -G '/usr/share/dnf5/repos.d/*.repo' >/dev/null; then
    cp /usr/share/dnf5/repos.d/*.repo /etc/yum.repos.d/
else
    echo "00-repos: warning: no repo files in /usr/share/dnf5/repos.d to bridge" >&2
fi

log_group_end