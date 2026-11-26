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

dnf -y install dnf-plugins-core dnf5-plugins

log_group_end