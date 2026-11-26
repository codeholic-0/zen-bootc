#!/usr/bin/bash
set -Eeuo pipefail

source /ctx/build_scripts/lib/common.sh
require_root
log_group "$(basename "$0")"

dnf -y install dnf-plugins-core dnf5-plugins
dnf makecache --refresh

log_group_end