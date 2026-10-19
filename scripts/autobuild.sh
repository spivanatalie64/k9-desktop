#!/usr/bin/env bash
set -euo pipefail
trap 'echo "ERROR: command failed at line $LINENO (exit $?)" >&2' ERR

# Determine latest Thunderbird ESR version
ESR=$(curl -s https://product-details.mozilla.org/1.0/thunderbird_versions.json \
  | python3 -c "import sys,json; print(json.load(sys.stdin)['THUNDERBIRD_ESR'])")
VER="${ESR%esr}"
BUILDID="$(date -u +%Y%m%d%H%M%S)"
echo "Target ESR: $ESR  (version $VER, build $BUILDID)"

# Skip if already released
if git rev-parse "v${VER}" >/dev/null 2>&1; then
  echo "Tag v${VER} already exists; nothing to do."
  exit 0
fi

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
cd "$WORK"

# Download and extract the ESR tarball
URL="https://ftp.mozilla.org/pub/thunderbird/releases/${ESR}/linux-x86_64/en-US/thunderbird-${ESR}.tar.xz"
echo "Downloading $URL"
curl -fL --progress-bar -o thunderbird.tar.xz "$URL"
tar -xJf thunderbird.tar.xz

# Move contents to repo root layout
cd thunderbird
# dereference symlinks
find . -type l -print0 | while IFS= read -r -d '' l; do
  if [ -e "$l" ]; then
    cp -L -- "$l" "$l.__tmp" && mv -f "$l.__tmp" "$l"
  fi
done

# move everything up one level into a staging dir
STAGE="$WORK/stage"
mkdir -p "$STAGE"
cp -a . "$STAGE/"
cd "$STAGE"

# rename binaries
[ -f thunderbird ] && mv -f thunderbird k9
[ -f thunderbird-bin ] && mv -f thunderbird-bin k9-bin

# sanitize absolute home paths
for f in $(grep -rl "/home/natalie" . 2>/dev/null || true); do
  sed -i 's#/home/natalie#/home/user#g' "$f"
done

# Write branded application.ini
cat > application.ini <<EOF
; This file is not used. If you modify it and want the application to use
; your modifications, start with the "-app /path/to/application.ini"
; argument.


[App]
Vendor=AcreetionOS
Name=K9Desktop
RemotingName=k9-default
CodeName=K-9 Desktop
Version=${VER}
Profile=k9
BuildID=${BUILDID}
SourceStamp=01ada2b85d92111c65b34af0364dc860d3f8e04b
ID={3550f703-e582-4d05-9a08-453d09bdfdc6}

[Gecko]
MinVersion=${VER}
MaxVersion=${VER}

[XRE]
EnableProfileMigrator=1
EOF

cat > platform.ini <<EOF

[Build]
BuildID=${BUILDID}
Milestone=${VER}
SourceStamp=ee9f2b2aedc3c58347d66ca8d7b9f92ef1df3f53
EOF

# Copy stage into repo root (overwrite)
REPO="${GITHUB_WORKSPACE:-/home/natalie/.ai/.src/k9-desktop}"
rsync -a --delete --exclude='.git' --exclude='.github' --exclude='scripts' "$STAGE/" "$REPO/"

cd "$REPO"

# LFS tracking for binaries
git lfs install >/dev/null 2>&1 || true
git add -A
git commit -m "Autobuild K9Desktop ${VER} based on Thunderbird ESR ${ESR}" || echo "No changes to commit"
git tag -a "v${VER}" -m "K9Desktop ${VER} release based on Mozilla Thunderbird LTS ${ESR}"
git push origin main
git push origin "v${VER}"

echo "Released v${VER}"