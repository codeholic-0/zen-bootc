# zen-bootc

**`main` is my personal OS.** It builds one image for my own machines: a
single `Containerfile`, one rolling tag (`:latest`), and dated anchors for
rollback. There are no flavors to promote and no staging pipeline.

If you're looking for the **generic multi-variant setup** (`testing`, `stable`,
`dev`, `minimal`), it is preserved on the frozen [`backup`](https://github.com/codeholic-0/zen-bootc/tree/backup)
branch. That branch is a reference snapshot, not an actively maintained image.

Published at: `ghcr.io/codeholic-0/zen-bootc`

## Pipeline

- Built from one [`Containerfile`](Containerfile) whose steps live in
  [`build_scripts/`](build_scripts) (repos → packages → multimedia → services →
  cleanup → validation), ending in `bootc container lint`.
- Smoke-tested inside the built image ([`.github/scripts/smoke.sh`](.github/scripts/smoke.sh))
  before anything is pushed.
- Rechunked with [chunkah](https://github.com/coreos/chunkah) → ~256 layers, so
  `bootc upgrade` pulls small deltas. Build-time mtimes are normalized so
  unchanged layers stay identical between builds.
- Cosign-signed by digest ([`cosign.pub`](cosign.pub); `SIGNING_SECRET`).
- In-image enforcement: [`policy.json`](policy.json) +
  [`registries.d/zen-bootc.yaml`](registries.d/zen-bootc.yaml) require a valid
  signature for pulls of this repo only.
- VSCodium's `extensionsGallery` is patched at build time to the marketplace
  endpoints in [`11-vscodium-gallery.sh`](build_scripts/base/11-vscodium-gallery.sh)
  (the stock Open VSX gallery was missing extensions).
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
zctl check            # probe digest + download size; also via /etc/cron.d/zctl (Sat 22:00)
zctl status           # tracking tag + running/staged digest + remote check
zctl upgrade          # stage an update (manual only)
zctl upgrade --apply
zctl switch           # browse :latest and dated anchors, probe, confirm → bootc switch
zctl switch --list    # read-only listing, no elevation
zctl remove-rollback  # remove the non-booted rollback deployment
zctl zdev          # install/refresh user-local zdev (no sudo)
```

Sudo is prompted for system commands except `zctl zdev` and `switch --list`;
detection is cron-automated; applying is manual.

CA trust and crypto-policy backends are regenerated at boot after upgrades, so
preserved `/etc` state doesn't go stale.

## zdev (user-local tooling)

`zdev` installs optional dev tooling into `$HOME` via each tool's official
upstream installer — never baked into the image, never touches `/usr`.
Run `zctl zdev` on any install (no sudo; refuses sudo/root, writes only
to `$HOME`).
Fallback one-liner:

```bash
zctl zdev
# fallback:
curl -fsSL https://raw.githubusercontent.com/codeholic-0/zen-bootc/main/zdev-install.sh | bash
```

```bash
zdev            # list tools + install state
zdev brew       # Homebrew (official installer)
zdev idea       # IntelliJ IDEA CE (latest GitHub release)
zdev sdkman     # SDKMAN!
zdev nvm        # nvm (latest GitHub release)
zdev uv         # uv (official astral installer)
zdev rust       # rust (official rustup installer)
zdev update     # self-update zdev from this repo
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
files/                             shipped files (zctl, cron, branding, drop-ins)
zdev                            user-local dev tooling helper (fetched from raw main)
zdev-install.sh                 fallback installer one-liner for zdev
docs/iso.md                        ISO build + SourceForge guide
files/usr/lib/bootc/kargs.d/10-plymouth.toml  boot kernel args
legacy/nix/                        dormant Nix-era leftovers; image has NO Nix
.github/workflows/bootc-publish.yaml CI: build → rechunk → smoke → stage+sign → publish
.github/workflows/iso-publish.yaml   CI: manual ISO → SourceForge
.github/workflows/cleanup-ghcr.yaml  CI: retain :latest + 5 dated anchors (weekly)
backup branch                      frozen generic multi-variant setup (reference only)
```

## Development loop

1. Edit `Containerfile`, `build_scripts/` or `files/`, push to `main`.
2. CI builds, rechunks, smoke-checks, signs the staged digest, then publishes
   `:latest`; install or `bootc upgrade` on the machine to test.
3. Pin a dated `latest-YYYYMMDD-sha7` anchor if you want to hold a known-good
   build; `zctl switch` moves between anchors.
4. For an installer, dispatch "Publish ISO" manually.
