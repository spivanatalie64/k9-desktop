# K9Desktop

K9Desktop is a privacy-first mail client based on Mozilla Thunderbird LTS, rebranded and de-telemetered for AcreetionOS — the desktop counterpart to K-9 Mail on mobile. The goal is the same as K-9 Mail's relationship to Thunderbird mobile: take the upstream client, strip telemetry and data collection, and ship a client that respects user sovereignty.

## Background

K-9 Mail was an independent, privacy-focused Android email client. Mozilla acquired it — along with its lead developer — to turn it into Thunderbird for Android, folding it into Mozilla's infrastructure and telemetry. K9Desktop is the inverse of that transaction: Thunderbird desktop ships with heavy telemetry and data collection, so we take Thunderbird LTS, remove the telemetry, crash reporting, experiments, and data reporting, rebrand it, and ship a client that answers to the user instead of to a vendor. This is what K-9 Mail was before the acquisition, applied to the desktop.

## What this repository contains

- The Thunderbird ESR application tree (binaries tracked with Git LFS).
- `scripts/autobuild.sh` — downloads the latest Thunderbird ESR release, rebrands it as K9Desktop, and commits the result.
- `scripts/package.sh` — packages the tree as `.deb`, `.rpm`, and Arch `.pkg.tar.zst`.
- `scripts/validate-packages.sh` — validates produced packages before release.
- `.github/workflows/autobuild.yml` — weekly GitHub Actions pipeline (free tier).

## Automation

The `K9Desktop Autobuild` workflow runs weekly (or on manual dispatch) in an `archlinux:latest` container:

1. Install build dependencies (`git`, `git-lfs`, `dpkg`, `rpm-tools`, etc.).
2. Clone the repository and pull LFS objects.
3. Run `scripts/autobuild.sh` to fetch the latest Thunderbird ESR tarball, rebrand binaries (`thunderbird` → `k9`), sanitize paths, write branded `application.ini`/`platform.ini`, commit, tag, and push.
4. Run `scripts/package.sh` to build deb, rpm, and Arch packages.
5. Run `scripts/validate-packages.sh` to verify metadata and desktop integration.
6. Create or update the GitHub release for that version and upload all artifacts.

## Packaging

Each package installs the application under `/opt/k9-desktop` (deb/rpm) or the system root (Arch) and adds:
- `/usr/bin/k9` launcher symlink
- `.desktop` entry and icons under `/usr/share`

## Privacy

K9Desktop disables telemetry and data reporting by default via `defaults/pref/k9-privacy.js` (telemetry, unified telemetry, health reports, Shield studies, discovery). The autobuild injects this file on every release.

```bash
git lfs pull
./scripts/package.sh
./scripts/validate-packages.sh dist
```

Requires `bsdtar`, `dpkg-deb`, and `rpmbuild` (Arch: `dpkg`, `rpm-tools`).
## Disclaimer and support

This project is an **automated autobuild** of Mozilla Thunderbird LTS. Builds are produced weekly by CI and may occasionally lag upstream or carry packaging rough edges.

- Found a bug? **Open an issue** on this repository.
- Need help sooner? Come talk to us on Discord: https://discord.acreetionos.org :D
