#!/usr/bin/env bash
# release.sh — Build, version, and publish a new GymTracker release to GitHub.
#
# Usage:
#   ./release.sh 1.0.1 "Release notes optionnelles"
#
# Prerequisites:
#   - gh CLI installed and authenticated (`brew install gh && gh auth login`)
#   - This folder must be inside a git repo with a GitHub remote
#   - First run: ensure AltStoreSource/source.json points to your repo

set -euo pipefail

cd "$(dirname "$0")"

if [[ -z "${1:-}" ]]; then
    echo "Usage: $0 <version> [release notes]"
    echo "Example: $0 1.0.1 \"Fix du timer de repos\""
    exit 1
fi

VERSION="$1"
NOTES="${2:-Mise à jour $VERSION}"
TAG="v$VERSION"

# 1. Update Info.plist version BEFORE building
PLIST="Resources/Info.plist"
if [[ -f "$PLIST" ]]; then
    /usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $VERSION" "$PLIST"
    echo "→ Info.plist version set to $VERSION"
fi

# 2. Build the .ipa
./build-ipa.sh

IPA_PATH="$(pwd)/build/GymTracker.ipa"
if [[ ! -f "$IPA_PATH" ]]; then
    echo "❌ build/GymTracker.ipa missing — build failed?"
    exit 1
fi

SIZE_BYTES=$(stat -f%z "$IPA_PATH")
TODAY=$(date +%Y-%m-%d)

# 2. Update source.json with the new version
SOURCE="AltStoreSource/source.json"
if [[ -f "$SOURCE" ]]; then
    echo "→ Updating $SOURCE with version $VERSION..."
    # Use python for safe JSON edit
    python3 - "$SOURCE" "$VERSION" "$TODAY" "$SIZE_BYTES" "$NOTES" "$TAG" <<'PY'
import json, sys
src, version, today, size, notes, tag = sys.argv[1:7]
with open(src) as f:
    data = json.load(f)

# Build the GitHub release URL from existing template if present
existing = data["apps"][0].get("versions", [])
download = ""
if existing and "downloadURL" in existing[0]:
    download = existing[0]["downloadURL"].replace(existing[0]["version"], version).replace(f"v{existing[0]['version']}", tag)

new_entry = {
    "version": version,
    "date": today,
    "localizedDescription": notes,
    "downloadURL": download or f"REPLACE_WITH_RELEASE_URL/GymTracker.ipa",
    "size": int(size),
    "minOSVersion": "17.0"
}

# Prepend new version
data["apps"][0]["versions"] = [new_entry] + existing
with open(src, "w") as f:
    json.dump(data, f, indent=2, ensure_ascii=False)
print(f"✅ source.json updated with version {version}")
PY
fi

# 3. Commit & push if in a git repo
if git rev-parse --git-dir >/dev/null 2>&1; then
    echo "→ Committing source.json bump..."
    git add "$SOURCE" "$PLIST" 2>/dev/null || true
    if ! git diff --cached --quiet; then
        git commit -m "Release $TAG" || true
        git push || echo "⚠️  Push failed — push manually later"
    fi
fi

# 4. Create GitHub release with the .ipa attached
if command -v gh >/dev/null 2>&1; then
    echo "→ Creating GitHub release $TAG..."
    gh release create "$TAG" "$IPA_PATH" \
        --title "GymTracker $VERSION" \
        --notes "$NOTES" \
        || echo "⚠️  Release creation failed — you can do it manually via 'gh release create'"
    echo ""
    echo "✅ Release published. AltStore will pick it up on next refresh."
else
    echo ""
    echo "⚠️  gh CLI not installed — install with: brew install gh && gh auth login"
    echo "    Then run: gh release create $TAG \"$IPA_PATH\" --title \"GymTracker $VERSION\""
fi
