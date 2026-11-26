# zen-bootc

**`main` is my personal OS.** It builds one image for my own machines: a
single `Containerfile`, one rolling tag (`:latest`), and dated anchors for
rollback. There are no flavors to promote and no staging pipeline.

If you're looking for the **generic multi-variant setup** (`testing`, `stable`,
`dev`, `minimal`), it is preserved on the frozen [`backup`](https://github.com/codeholic-0/zen-bootc/tree/backup)
branch. That branch is a reference snapshot, not an actively maintained image.

Published at: `ghcr.io/codeholic-0/zen-bootc`

## What's in the image

- **Base:** Fedora 45 Kinoite (KDE Plasma), rebranded as ZenC OS.
- **Debloated:** Firefox, Akonadi, Plasma Discover/Welcome, KWrite, KRfb and
  XwaylandVideoBridge are removed.
- **Multimedia:** `@multimedia` plus RPM Fusion `ffmpeg` (with tainted repos
  enabled), VLC, yt-dlp, gthumb, guvcview, media writer, and a Breeze Plymouth
  splash.
- **Browsers & desktop apps:** LibreWolf, Helium, Persepolis, Kate, Zenity.
- **Dev toolchain (baked in):** gcc/g++, clang, gdb, make/cmake, autotools,
  VSCodium, Neovim, git/git-lfs/gh, jq/yq/sqlite, shellcheck, and Verilog tools
  (iverilog, verilator, gtkwave).
- **Shell & CLI:** zsh, bat, eza, fd, fzf, zoxide, btop, fastfetch, lm_sensors,
  smem, dos2unix, plocate, distrobox.
- **Containers & storage:** Docker CE (compose/buildx plugins), Podman,
  podman-compose, Flatpak/Flathub, Btrfs tools, cryfs, scrub.
- **Services & tuning:** NetworkManager, KDE login (`plasmalogin`), Docker, earlyoom and
  cron enabled; `NetworkManager-wait-online` disabled/masked.
- **Transport security:** images are cosign-signed; in-image policy enforces
  valid signatures for this repo only.
- No Nix — `legacy/nix/` is dormant history. Optional user-local tooling lives
  in `zen-dev`, never in `/usr`.

## Pipeline

- Built from one [`Containerfile`](Containerfile) whose steps live in
  [`build_scripts/`](build_scripts) (repos → packages → multimedia → services →
  cleanup → validation), ending in `bootc container lint`.
- Smoke-tested inside the built image ([`.github/scripts/smoke.sh`](.github/scripts/smoke.sh))
  before anything is pushed.
- Rechunked with [chunkah](https://github.com/coreos/chunkah) → ~128 layers, so
  `bootc upgrade` pulls small deltas.
- Cosign-signed by digest ([`cosign.pub`](cosign.pub); `SIGNING_SECRET`).
- In-image enforcement: [`policy.json`](policy.json) +
  [`registries.d/zen-bootc.yaml`](registries.d/zen-bootc.yaml) require a valid
  signature for pulls of this repo only.
- Weekly rebuild (Sat ~18:05 UTC, `--pull=newer`) plus path-filtered CI.
- `latest-YYYYMMDD-sha7` tags are immutable rollback anchors.
- Weekly GHCR cleanup keeps `:latest` plus the 5 newest dated anchors; older
  anchors are pruned (legacy flavor tags are left alone).
- Installer ISO (manual dispatch) → SourceForge. See [`docs/iso.md`](docs/iso.md).

## Usage

```bash
# first install / replace base
bootc switch --mutate-in-place --transport registry ghcr.io/codeholic-0/zen-bootc:latest

# update / rollback
bootc upgrade
bootc rollback            # or switch to a dated latest- tag to pin further

# verify signature
cosign verify --key cosign.pub ghcr.io/codeholic-0/zen-bootc:latest
```

Installer ISO: Actions → "Publish ISO" (one role, no checkboxes), or
`gh workflow run iso-publish.yaml --ref main` — see [`docs/iso.md`](docs/iso.md).

## Updates

```bash
zen-ctl check            # probe digest + download size; also via /etc/cron.d/zen-ctl (Sat 22:00)
zen-ctl status           # tracking tag + running/staged digest + remote check
zen-ctl upgrade          # stage an update (manual only)
zen-ctl upgrade --apply
zen-ctl switch           # browse :latest and dated anchors, probe, confirm → bootc switch
zen-ctl switch --list    # read-only listing, no elevation
zen-ctl remove-rollback  # remove the non-booted rollback deployment
zen-ctl zen-dev          # install/refresh user-local zen-dev (no sudo)
```

Sudo is prompted for system commands except `zen-ctl zen-dev` and `switch --list`;
detection is cron-automated; applying is manual.

## zen-dev (user-local tooling)

`zen-dev` installs optional dev tooling into `$HOME` via each tool's official
upstream installer — never baked into the image, never touches `/usr`.
Run `zen-ctl zen-dev` on any install (no sudo; refuses sudo/root, writes only
to `$HOME`).
Fallback one-liner:

```bash
zen-ctl zen-dev
# fallback:
curl -fsSL https://raw.githubusercontent.com/codeholic-0/zen-bootc/main/zen-dev-install.sh | bash
```

```bash
zen-dev            # list tools + install state
zen-dev brew       # Homebrew (official installer)
zen-dev idea       # IntelliJ IDEA CE (latest GitHub release)
zen-dev sdkman     # SDKMAN!
zen-dev nvm        # nvm (latest GitHub release)
zen-dev uv         # uv (official astral installer)
zen-dev rust       # rust (official rustup installer)
zen-dev update     # self-update zen-dev from this repo
```

Versions resolve live from upstream at install time — nothing pinned.
bash/zsh login shells get rc init lines automatically; other shells:
idea/uv/rust/brew work anywhere, sdkman/nvm abort.

## Repo layout

```
Containerfile                      single image spec (build_ctx + build_scripts)
build_scripts/                     grouped install/config/validation steps
policy.json                        signed-ref policy shipped into the image
cosign.pub                         public key for signature enforcement
registries.d/                      registries.d snippet shipped into the image
disk_config/iso-kde.toml           bootc-image-builder config for the ISO
files/                             shipped files (zen-ctl, cron, branding, drop-ins)
zen-dev                            user-local dev tooling helper (fetched from raw main)
zen-dev-install.sh                 fallback installer one-liner for zen-dev
docs/iso.md                        ISO build + SourceForge guide
files/usr/lib/bootc/kargs.d/10-plymouth.toml  boot kernel args
legacy/nix/                        dormant Nix-era leftovers; image has NO Nix
.github/workflows/bootc-publish.yaml CI: build → smoke → rechunk → push → sign
.github/workflows/iso-publish.yaml   CI: manual ISO → SourceForge
.github/workflows/cleanup-ghcr.yaml  CI: retain :latest + 5 dated anchors (weekly)
testing/                           work notes + reference clones (gitignored)
backup branch                      frozen generic multi-variant setup (reference only)
```

## Development loop

1. Edit `Containerfile`, `build_scripts/` or `files/`, push to `main`.
2. CI builds, smoke-checks, rechunks, signs and publishes `:latest`; install or
   `bootc upgrade` on the machine to test.
3. Pin a dated `latest-YYYYMMDD-sha7` anchor if you want to hold a known-good
   build; `zen-ctl switch` moves between anchors.
4. For an installer, dispatch "Publish ISO" manually.
