#!/bin/bash
# build script for mac apps
# in this script we assume gnu cli utils

CODESIGNING=DEVELOPMENT_TEAM=AWMJ8H4G7B
ARCHIVE_DIR=archive/Applications

set -euo pipefail
set -x

cd "$(dirname "$0")"
mkdir -p "$ARCHIVE_DIR"

(
  cd ./Ice
  xcodebuild -scheme Ice -configuration Release \
    -derivedDataPath ./DerivedData \
    "$CODESIGNING"
  /bin/cp -acf ./DerivedData/Build/Products/Release/Ice.app ../"$ARCHIVE_DIR"
)
