#!/bin/bash
#
# Archives the AppBox SDK example app and uploads it with appboxcli, keeping the same
# install link for every future build so the SDK inside an installed build finds the next one.
#
# Usage:
#   Scripts/upload.sh                              archive, export, upload
#   Scripts/upload.sh --check                      preflight only, upload nothing
#   Scripts/upload.sh --ipa build/Example.ipa      upload a prebuilt IPA, skip the build
#   Scripts/upload.sh --emails you@example.com     email the install link too
#   Scripts/upload.sh --message "New login screen"
#   Scripts/upload.sh --set-link                   write the link into ExampleConfiguration.swift
#
# Build output goes to build/logs/ and is only shown when something fails.
#
# Options:
#   --ipa PATH            upload this IPA instead of building one
#   --build-number N      CFBundleVersion to stamp (default: the current UTC timestamp)
#   --method METHOD       export method: debugging, release-testing or enterprise (default: debugging)
#   --team ID             signing team (default: the project's DEVELOPMENT_TEAM)
#   --emails LIST         comma-separated addresses that get the install link
#   --message TEXT        personal message shown under "Message from the developer"
#   --dbfolder NAME       custom Dropbox folder instead of the bundle identifier
#   --slack-webhook URL   post the build to a Slack channel
#   --teams-webhook URL   post the build to a Microsoft Teams channel
#   --set-link            patch fallbackInstallLink in ExampleConfiguration.swift with the link
#   --check               run the preflight checks and stop
#   --verbose             stream the full build and upload logs instead of hiding them
#   -h, --help            this text
#
set -uo pipefail

EXAMPLE_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROJECT="$EXAMPLE_ROOT/AppBoxSDKExample.xcodeproj"
SCHEME="AppBoxSDKExample"
CONFIG_SWIFT="$EXAMPLE_ROOT/AppBoxSDKExample/ExampleConfiguration.swift"
BUILD_DIR="$EXAMPLE_ROOT/build"
LOG_DIR="$BUILD_DIR/logs"
SHARE_FILE="$HOME/.appbox_share_value.json"

IPA=""
BUILD_NUMBER="$(date -u +%Y%m%d%H%M)"
METHOD="debugging"
TEAM=""
EMAILS=""
MESSAGE=""
DB_FOLDER=""
SLACK_WEBHOOK=""
TEAMS_WEBHOOK=""
SET_LINK=0
CHECK_ONLY=0
VERBOSE=0

while [ $# -gt 0 ]; do
  case "$1" in
    --ipa)            IPA="${2:?--ipa needs a path}"; shift ;;
    --build-number)   BUILD_NUMBER="${2:?--build-number needs a value}"; shift ;;
    --method)         METHOD="${2:?--method needs a value}"; shift ;;
    --team)           TEAM="${2:?--team needs a team id}"; shift ;;
    --emails)         EMAILS="${2:?--emails needs an address}"; shift ;;
    --message)        MESSAGE="${2:?--message needs text}"; shift ;;
    --dbfolder)       DB_FOLDER="${2:?--dbfolder needs a name}"; shift ;;
    --slack-webhook)  SLACK_WEBHOOK="${2:?--slack-webhook needs a URL}"; shift ;;
    --teams-webhook)  TEAMS_WEBHOOK="${2:?--teams-webhook needs a URL}"; shift ;;
    --set-link)       SET_LINK=1 ;;
    --check)          CHECK_ONLY=1 ;;
    --verbose)        VERBOSE=1 ;;
    -h|--help)        sed -n '2,29p' "$0" | sed 's/^#//; s/^ //'; exit 0 ;;
    *) printf 'Unknown option: %s\nRun with --help.\n' "$1" >&2; exit 2 ;;
  esac
  shift
done

pass() { printf '  \033[32m✓\033[0m %s\n' "$1"; }
fail() { printf '  \033[31m✗\033[0m %s\n' "$1"; FAILED=1; }
warn() { printf '  \033[33m!\033[0m %s\n' "$1"; }
step() { printf '\n\033[34m==>\033[0m %s\n' "$1"; }
FAILED=0

# The lines that say what went wrong, else the tail of the log. Everything else stays in the file.
show_errors() {
  local log="$1" found
  found="$(grep -E "error:|fatal error|\*\* [A-Z ]*FAILED \*\*" "$log" 2>/dev/null | sort -u | head -15)"
  if [ -n "$found" ]; then
    printf '%s\n' "$found" | sed 's/^/      /'
  else
    printf '      last 15 lines:\n'
    tail -15 "$log" 2>/dev/null | sed 's/^/      /'
  fi
  printf '\n  full log: %s\n' "$log"
}

# Runs CMD with its output in a log file. Nothing reaches the terminal unless it fails, or --verbose.
run_logged() {
  local log="$1" what="$2" status
  mkdir -p "$LOG_DIR"
  if [ "$VERBOSE" -eq 1 ]; then
    "${CMD[@]}" 2>&1 | tee "$log"
    status="${PIPESTATUS[0]}"
  else
    "${CMD[@]}" >"$log" 2>&1
    status=$?
  fi
  [ "$status" -eq 0 ] && return 0
  fail "$what failed"
  show_errors "$log"
  return "$status"
}

step "Preflight"

if [ -d "$PROJECT" ]; then
  pass "example project found"
else
  fail "example project missing: $PROJECT"
fi

# The plugin and this script both drive the CLI, which is what actually talks to Dropbox.
if CLI="$(command -v appboxcli)"; then
  pass "appboxcli on PATH ($CLI)"
else
  fail "appboxcli not found — install it from AppBox ▸ Preferences ▸ General, or see https://docs.getappbox.com/CommandLineInterface/"
fi

# The CLI and the app share one Dropbox session, so this is the real gate on whether an upload can succeed.
if command -v appboxcli >/dev/null 2>&1; then
  if ACCOUNT="$(appboxcli whoami 2>&1)" && [ -n "$ACCOUNT" ]; then
    pass "Dropbox linked — $(printf '%s' "$ACCOUNT" | head -1)"
  else
    fail "not logged in to Dropbox — run: appboxcli login"
  fi
fi

if [ -n "$IPA" ]; then
  if [ -f "$IPA" ] && unzip -tqq "$IPA" >/dev/null 2>&1; then
    pass "IPA present and readable ($(du -h "$IPA" | cut -f1))"
  else
    fail "IPA missing or corrupt: $IPA"
  fi
elif command -v xcodebuild >/dev/null 2>&1; then
  pass "xcodebuild available ($(xcodebuild -version 2>/dev/null | head -1))"
else
  fail "xcodebuild not found — install Xcode to build the example"
fi

if [ -z "$TEAM" ] && [ -d "$PROJECT" ]; then
  TEAM="$(xcodebuild -project "$PROJECT" -scheme "$SCHEME" -showBuildSettings 2>/dev/null \
    | awk -F' = ' '/ DEVELOPMENT_TEAM = /{print $2; exit}')"
fi
if [ -n "$TEAM" ]; then
  pass "signing team $TEAM"
else
  warn "no signing team — pass --team ID if the export cannot pick one"
fi

if [ "$SET_LINK" -eq 1 ]; then
  if grep -q 'fallbackInstallLink' "$CONFIG_SWIFT" 2>/dev/null; then
    pass "ExampleConfiguration.swift can be patched"
  else
    fail "no fallbackInstallLink in $CONFIG_SWIFT"
  fi
fi

if [ "$FAILED" -ne 0 ]; then
  printf '\n\033[31mPreflight failed.\033[0m Fix the items above and re-run.\n\n'
  exit 1
fi

if [ "$CHECK_ONLY" -eq 1 ]; then
  printf '\n\033[32mPreflight passed.\033[0m Re-run without --check to build and upload.\n\n'
  exit 0
fi

# MARK: - Build

if [ -z "$IPA" ]; then
  ARCHIVE="$BUILD_DIR/$SCHEME.xcarchive"
  EXPORT_DIR="$BUILD_DIR/export"
  EXPORT_OPTIONS="$BUILD_DIR/ExportOptions.plist"

  step "Archiving $SCHEME (build $BUILD_NUMBER)"
  rm -rf "$ARCHIVE" "$EXPORT_DIR"
  mkdir -p "$BUILD_DIR"

  # The project generates its Info.plist, so CFBundleVersion comes straight from this setting —
  # no need to commit a bumped build number back into the project.
  CMD=(xcodebuild archive
       -project "$PROJECT"
       -scheme "$SCHEME"
       -configuration Release
       -destination 'generic/platform=iOS'
       -archivePath "$ARCHIVE"
       CURRENT_PROJECT_VERSION="$BUILD_NUMBER")
  [ -n "$TEAM" ] && CMD+=(DEVELOPMENT_TEAM="$TEAM")

  run_logged "$LOG_DIR/archive.log" "Archive" || exit 1
  pass "archived"

  step "Exporting a $METHOD IPA"
  cat > "$EXPORT_OPTIONS" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>method</key>
	<string>$METHOD</string>
	<key>signingStyle</key>
	<string>automatic</string>
	<key>stripSwiftSymbols</key>
	<true/>
	<key>compileBitcode</key>
	<false/>
$([ -n "$TEAM" ] && printf '\t<key>teamID</key>\n\t<string>%s</string>\n' "$TEAM")
</dict>
</plist>
PLIST

  CMD=(xcodebuild -exportArchive
       -archivePath "$ARCHIVE"
       -exportPath "$EXPORT_DIR"
       -exportOptionsPlist "$EXPORT_OPTIONS")

  if ! run_logged "$LOG_DIR/export.log" "Export"; then
    printf '  a %s export needs a matching signing certificate and provisioning profile\n\n' "$METHOD"
    exit 1
  fi

  IPA="$(find "$EXPORT_DIR" -maxdepth 1 -name '*.ipa' | head -1)"
  if [ -z "$IPA" ]; then
    fail "no IPA in $EXPORT_DIR"
    exit 1
  fi
  pass "exported $(basename "$IPA") ($(du -h "$IPA" | cut -f1))"
fi

# MARK: - Upload

step "Uploading to AppBox"

# --keepsamelink is the point of this script: one install link for the life of the app, which is
# what lets the SDK in an already-installed build find the next upload.
ARGS=(upload --ipa "$IPA" --keepsamelink)
[ -n "$EMAILS" ]        && ARGS+=(--emails "$EMAILS")
[ -n "$MESSAGE" ]       && ARGS+=(--message "$MESSAGE")
[ -n "$DB_FOLDER" ]     && ARGS+=(--dbfolder "$DB_FOLDER")
[ -n "$SLACK_WEBHOOK" ] && ARGS+=(--slackwebhook "$SLACK_WEBHOOK")
[ -n "$TEAMS_WEBHOOK" ] && ARGS+=(--msteamswebhook "$TEAMS_WEBHOOK")

UPLOAD_LOG="$LOG_DIR/upload.log"
mkdir -p "$LOG_DIR"
rm -f "$SHARE_FILE"

if [ "$VERBOSE" -eq 1 ]; then
  appboxcli "${ARGS[@]}" 2>&1 | tee "$UPLOAD_LOG"
  STATUS="${PIPESTATUS[0]}"
else
  # The CLI repeats each stage line for every percent it advances; collapse that to stage changes,
  # so a long upload still shows progress without scrolling.
  appboxcli "${ARGS[@]}" 2>&1 | tee "$UPLOAD_LOG" | awk '
    {
      line = $0
      sub(/ \([0-9]+%\)$/, "", line)
      if (line != "" && line != last) {
        printf "  \033[2m%s\033[0m\n", line
        fflush()
        last = line
      }
    }'
  STATUS="${PIPESTATUS[0]}"
fi

# 111 means the build is live but the notification email could not be sent.
if [ "$STATUS" -eq 111 ]; then
  warn "the build is live, but the email could not be sent"
elif [ "$STATUS" -ne 0 ]; then
  fail "upload failed (exit $STATUS)"
  show_errors "$UPLOAD_LOG"
  exit 1
fi

step "Result"

if [ ! -f "$SHARE_FILE" ]; then
  fail "no $SHARE_FILE — the upload reported success but wrote no links"
  exit 1
fi

read_share_value() {
  python3 -c "import json,sys;print(json.load(open(sys.argv[1])).get(sys.argv[2],''))" "$SHARE_FILE" "$1" 2>/dev/null
}

SHARE_URL="$(read_share_value APPBOX_SHARE_URL)"
for key in APPBOX_SHARE_URL APPBOX_IPA_URL APPBOX_MANIFEST_URL; do
  value="$(read_share_value "$key")"
  if [ -n "$value" ]; then pass "$key = $value"; else warn "$key is empty"; fi
done

if [ -z "$SHARE_URL" ]; then
  fail "no install link to report"
  exit 1
fi

if [ "$SET_LINK" -eq 1 ]; then
  if python3 - "$CONFIG_SWIFT" "$SHARE_URL" <<'PY'
import re, sys

path, link = sys.argv[1], sys.argv[2]
source = open(path).read()
pattern = r'(private static let fallbackInstallLink = )"[^"]*"'
patched, count = re.subn(pattern, lambda m: m.group(1) + '"' + link + '"', source, count=1)
if count == 0:
    sys.exit(1)
open(path, 'w').write(patched)
PY
  then
    pass "fallbackInstallLink set in ExampleConfiguration.swift"
    warn "rebuild and re-upload once so the shipped build watches this link"
  else
    fail "could not patch $CONFIG_SWIFT — set fallbackInstallLink by hand"
  fi
else
  printf '\n\033[33mNext:\033[0m put this link in fallbackInstallLink in\n  %s\nso the SDK watches this app, or re-run with --set-link to do it here.\n' "$CONFIG_SWIFT"
fi

printf '\n\033[32mDone.\033[0m Open the install link on an iOS device to install build %s.\n\n' "$BUILD_NUMBER"
