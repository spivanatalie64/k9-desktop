#!/usr/bin/env bash
set -euo pipefail

DIST="${1:-dist}"
RPMDB="$(mktemp -d)"
TMP="$(mktemp -d)"
trap 'rm -rf "$RPMDB" "$TMP"' EXIT
mkdir -p "$RPMDB"

fail=0
check() {
  if ! "$@"; then
    echo "FAIL: $*" >&2
    fail=1
  fi
}

shopt -s nullglob

# --- Arch packages ---
for f in "$DIST"/*.pkg.tar.zst; do
  echo "Validating $f"
  check pacman -Qp "$f" >/dev/null
  check bsdtar -xOf "$f" .PKGINFO >/dev/null
  check bsdtar -xOf "$f" .BUILDINFO >/dev/null
  check sh -c "bsdtar -xOf '$f' .MTREE | gzip -t"
  bsdtar -tf "$f" > "$TMP/arch.list"
  check grep -qx 'usr/bin/k9' "$TMP/arch.list"
  check grep -qx 'defaults/pref/k9-privacy.js' "$TMP/arch.list"
  check sh -c "! grep -qx 'pingsender' '$TMP/arch.list'"
done

# --- Debian packages ---
for f in "$DIST"/*.deb; do
  echo "Validating $f"
  check dpkg-deb -I "$f" >/dev/null
  dpkg-deb -c "$f" > "$TMP/deb.list"
  check grep -q './usr/bin/k9' "$TMP/deb.list"
  check grep -q 'k9-desktop.desktop' "$TMP/deb.list"
  check grep -q 'defaults/pref/k9-privacy.js' "$TMP/deb.list"
  check sh -c "! grep -q './pingsender' '$TMP/deb.list'"
done

# --- RPM packages ---
for f in "$DIST"/*.rpm; do
  echo "Validating $f"
  check rpm -qpl --dbpath "$RPMDB" "$f" >/dev/null
  rpm -qpl --dbpath "$RPMDB" "$f" > "$TMP/rpm.list"
  check grep -qx '/usr/bin/k9' "$TMP/rpm.list"
  check grep -qx '/usr/share/applications/k9-desktop.desktop' "$TMP/rpm.list"
  check grep -qx '/opt/k9-desktop/defaults/pref/k9-privacy.js' "$TMP/rpm.list"
  check sh -c "! grep -qx '/opt/k9-desktop/pingsender' '$TMP/rpm.list'"
done

if [ "$fail" -ne 0 ]; then
  echo "Package validation failed" >&2
  exit 1
fi
echo "All packages validated successfully"