#!/usr/bin/bash
set -Eeuo pipefail

source /ctx/build_scripts/lib/common.sh
require_root
log_group "$(basename "$0")"

dnf -y install @multimedia
if rpm -q ffmpeg-free >/dev/null 2>&1; then
    dnf -y swap ffmpeg-free ffmpeg --allowerasing
else
    dnf -y install ffmpeg --allowerasing
fi

dnf_install vlc yt-dlp gthumb guvcview

log_group_end