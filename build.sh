#!/bin/bash
# build script for mac apps
# in this script we assume gnu cli utils

SET_DEVELOPMENT_TEAM=DEVELOPMENT_TEAM=AWMJ8H4G7B
ARCHIVE_DIR=archive/Applications
PNAME=darwin-apps
STORE_PATH_FILE="$PNAME.txt"

set -euo pipefail
set -x

cd "$(dirname "$0")"
mkdir -p "$ARCHIVE_DIR"

(
  cd ./Ice
  xcodebuild -scheme Ice -configuration Release \
    -derivedDataPath ./DerivedData \
    "$SET_DEVELOPMENT_TEAM"
  /bin/cp -acf ./DerivedData/Build/Products/Release/Ice.app ../"$ARCHIVE_DIR"
)

(
  if ! command -v pod &>/dev/null; then
    echo "require cocoapods: brew install cocoapods"
    exit 1
  fi

  cd ./automute
  patch < ../automute-signing.patch
  pod install
  xcodebuild -workspace automute.xcworkspace -scheme AutoMute -configuration Release \
    -derivedDataPath ./DerivedData \
    -allowProvisioningUpdates \
    "$SET_DEVELOPMENT_TEAM" \
    CODE_SIGN_IDENTITY="Apple Development"
  /bin/cp -acf ./DerivedData/Build/Products/Release/AutoMute.app ../"$ARCHIVE_DIR"
  git restore 'Pod*'
)

(
  cd ./AltTab

  # update version; see:
  # - ./.github/workflows/ci_cd.yml
  # - ./scripts/replace_environment_variables_in_app.sh
  version=$(git describe --tags --match='v*' | sed 's/^v//')
  sed -i '' -e "s/#VERSION#/$version/" Info.plist

  xcodebuild -scheme Release -workspace alt-tab-macos.xcworkspace \
    -derivedDataPath ./DerivedData \
    CODE_SIGN_IDENTITY="Apple Development: bryanlai@foxmail.com (VY3W9R894Q)" \
    MACOSX_DEPLOYMENT_TARGET=10.13
  /bin/cp -acf ./DerivedData/Build/Products/Release/AltTab.app ../"$ARCHIVE_DIR"

  git restore Info.plist
)

(
  cd ./MiddleClick
  patch < ../MiddleClick-dev-team.patch
  make
  /bin/cp -acf ./build/MiddleClick.app ../"$ARCHIVE_DIR"
  git restore Makefile
)

(
  cd ./Rectangle
  xcodebuild -scheme Rectangle -configuration Release \
    -derivedDataPath ./DerivedData \
    "$SET_DEVELOPMENT_TEAM"
  /bin/cp -acf ./DerivedData/Build/Products/Release/Rectangle.app ../"$ARCHIVE_DIR"
)

nix store add --name "$PNAME" ./archive > "$STORE_PATH_FILE"
git add --intent-to-add "$STORE_PATH_FILE"
cachix push chezbryan "$(cat "$STORE_PATH_FILE")"
cat "$STORE_PATH_FILE"
