#!/bin/zsh
set -euo pipefail

project_dir="${0:A:h}"
cd "$project_dir"

swift build -c release

app_path="dist/vindR.app"
archive_path="dist/vindR-macOS.zip"
stage_path="$(mktemp -d)"
trap '/bin/rm -rf "$stage_path"' EXIT

/bin/rm -rf "$app_path"
mkdir -p "$app_path/Contents/MacOS" "$app_path/Contents/Resources"
cp ".build/release/vindR" "$app_path/Contents/MacOS/vindR"
cp "Support/Info.plist" "$app_path/Contents/Info.plist"
cp "Sources/vindR/Resources/AppIcon.icns" "$app_path/Contents/Resources/AppIcon.icns"
ditto ".build/release/vindR_vindR.bundle" "$app_path/vindR_vindR.bundle"

ditto "$app_path" "$stage_path/vindR.app"
cp "user-manual.md" "$stage_path/user-manual.md"
/bin/rm -f "$archive_path"
pushd "$stage_path" >/dev/null
/usr/bin/zip -qry "$project_dir/$archive_path" "vindR.app" "user-manual.md"
popd >/dev/null

echo "$app_path"
echo "$archive_path"
