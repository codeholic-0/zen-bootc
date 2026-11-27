#!/usr/bin/bash
set -Eeuo pipefail

source /ctx/build_scripts/lib/common.sh
require_root
log_group "$(basename "$0")"

base_ver=$(. /etc/os-release && printf '%s' "$VERSION_ID")
if [ "${base_ver}" != "${FEDORA_VER:-}" ]; then
    echo "build-prep: FEDORA_VER='${FEDORA_VER:-unset}' does not match base VERSION_ID='${base_ver}'" >&2
    exit 1
fi

dnf -y install dnf5-plugins

# Build-only DNF tuning: keep downloaded metadata/RPMs and avoid long stalls.
# Restored in shared/cleanup.sh so it is not shipped in the image.
cp /etc/dnf/dnf.conf /etc/dnf/dnf.conf.bak
dnf config-manager setopt keepcache=1 timeout=60

log_group_end