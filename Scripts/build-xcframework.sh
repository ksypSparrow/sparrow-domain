#!/bin/bash
# Builds SparrowDomain.xcframework.
#
# ⚠️ Two things make this work, and both are easy to undo by accident:
#
#   1. The products are `type: .dynamic`. A static product gives you an
#      object file and no framework to package.
#   2. Nothing here may leak a non-system module into the public
#      .swiftinterface, or every consumer needs that module at compile time.
#      Domain imports only Foundation, so this costs nothing today.
#
# SwiftPM builds the framework without a Modules directory, so the .swiftmodule
# is copied in by hand before packaging. That step is not optional; without it
# the xcframework cannot be imported.
set -euo pipefail

NAME="${1:-SparrowDomain}"
OUT="${OUT:-$PWD/build}"
DD="$OUT/dd"

rm -rf "$OUT/$NAME.xcframework"
ARGS=()

for dest in "generic/platform=iOS Simulator:Release-iphonesimulator" \
            "generic/platform=iOS:Release-iphoneos"; do
    destination="${dest%%:*}"
    config="${dest##*:}"

    xcodebuild build -scheme "$NAME" -destination "$destination" \
        -derivedDataPath "$DD" -configuration Release \
        BUILD_LIBRARY_FOR_DISTRIBUTION=YES SKIP_INSTALL=NO > /dev/null

    products="$DD/Build/Products/$config"
    framework="$products/PackageFrameworks/$NAME.framework"
    mkdir -p "$framework/Modules"
    cp -R "$products/$NAME.swiftmodule" "$framework/Modules/"
    ARGS+=(-framework "$framework")
done

xcodebuild -create-xcframework "${ARGS[@]}" -output "$OUT/$NAME.xcframework"

cd "$OUT"
rm -f "$NAME.xcframework.zip"
zip -qry "$NAME.xcframework.zip" "$NAME.xcframework"
echo "$OUT/$NAME.xcframework.zip"
swift package compute-checksum "$NAME.xcframework.zip" 2>/dev/null \
    || (cd - > /dev/null && swift package compute-checksum "$OUT/$NAME.xcframework.zip")
