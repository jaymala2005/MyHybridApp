#!/bin/bash
# Build MyHybridApp for the iOS Simulator and launch it (run on the Mac).
# Usage: scripts/run-ios-sim.sh ["iPhone 17 Pro"]
set -euo pipefail

export DOTNET_ROOT="$HOME/.dotnet" PATH="$HOME/.dotnet:$PATH" DOTNET_CLI_TELEMETRY_OPTOUT=1 DOTNET_NOLOGO=1

DEVICE_NAME="${1:-iPhone 17 Pro}"
BUNDLE_ID="com.companyname.myhybridapp"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
RID="iossimulator-$(uname -m | sed 's/x86_64/x64/')"
APP="$ROOT/MyHybridApp/bin/Debug/net10.0-ios/$RID/MyHybridApp.app"

UDID=$(xcrun simctl list devices available | grep -m1 -F "    $DEVICE_NAME (" | sed -E 's/.*\(([0-9A-F-]{36})\).*/\1/')
[ -n "$UDID" ] || { echo "No available simulator named '$DEVICE_NAME'"; xcrun simctl list devices available | grep iPhone; exit 1; }
echo "==> Simulator: $DEVICE_NAME ($UDID)"

echo "==> Building ($RID)"
# TargetFrameworks override keeps restore from requiring the Android workload.
dotnet build "$ROOT/MyHybridApp/MyHybridApp.csproj" -f net10.0-ios -c Debug \
    -p:TargetFrameworks=net10.0-ios -p:RuntimeIdentifier="$RID" -v:m -nologo

echo "==> Booting simulator"
xcrun simctl boot "$UDID" 2>/dev/null || true
xcrun simctl bootstatus "$UDID" -b >/dev/null
open -a Simulator --args -CurrentDeviceUDID "$UDID" 2>/dev/null || echo "   (Simulator window needs a desktop session; connect with Remote Desktop to see it)"

echo "==> Installing and launching"
xcrun simctl install "$UDID" "$APP"
xcrun simctl terminate "$UDID" "$BUNDLE_ID" 2>/dev/null || true
xcrun simctl launch "$UDID" "$BUNDLE_ID"

sleep 8
xcrun simctl io "$UDID" screenshot "$ROOT/ios-sim-screenshot.png" >/dev/null 2>&1 && echo "==> Screenshot: $ROOT/ios-sim-screenshot.png"
