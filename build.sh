#!/bin/bash
# build script for mac apps
# in this script we assume gnu cli utils

set -euo pipefail
set -x

cd "$(dirname "$0")"
CODESIGNING=DEVELOPMENT_TEAM=AWMJ8H4G7B

(
  cd ./Ice
  xcodebuild -scheme Ice -configuration Release \
    -derivedDataPath ./DerivedData \
    "$CODESIGNING"
  cp -af --reflink=auto ./DerivedData/Build/Products/Release/Ice.app ../archive/Applications
)

pwd
