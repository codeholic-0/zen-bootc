#!/usr/bin/bash
set -Eeuo pipefail

source /ctx/build_scripts/lib/common.sh
require_root
log_group "$(basename "$0")"

dnf -y swap ffmpeg-free ffmpeg --allowerasing
dnf -y install @multimedia

dnf_install \
    plymouth \
    plymouth-system-theme \
    plymouth-theme-breeze

log_group_end