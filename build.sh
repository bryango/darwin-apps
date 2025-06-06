#!/bin/bash
# build script for mac apps

# set up code signing identities
[[ -n $DEVELOPMENT_TEAM ]] || DEVELOPMENT_TEAM=AWMJ8H4G7B
[[ -n $CODE_SIGN_IDENTITY ]] || CODE_SIGN_IDENTITY="Apple Development"

# set up packaging with nix & cachix
[[ -n $CACHIX_CACHE ]] || CACHIX_CACHE=chezbryan
[[ -n $PNAME ]] || PNAME=darwin-apps
STORE_PATH_FILE="$PNAME.txt"

set -euo pipefail

SET_DEVELOPMENT_TEAM=DEVELOPMENT_TEAM="$DEVELOPMENT_TEAM"
SET_CODE_SIGN_IDENTITY=CODE_SIGN_IDENTITY="$CODE_SIGN_IDENTITY"

FLAG_RELEASE=("-configuration" "Release")
FLAG_DERIVED_DATA=("-derivedDataPath" "./DerivedData")

PROJECT_DIR="$(dirname "$0")"
ARCHIVE_APPS=_archive/Applications
DERIVED_RELEASE=./DerivedData/Build/Products/Release

set -x

cd "$PROJECT_DIR"
mkdir -p "$ARCHIVE_APPS"

# make sure we use `cp` from macos
# which supports the `-c` flag for clonefile
cp() { /bin/cp "$@"; }

(
  cd ./AlDente
  xcodebuild -scheme AlDente \
    "${FLAG_RELEASE[@]}" \
    "${FLAG_DERIVED_DATA[@]}" \
    "$SET_DEVELOPMENT_TEAM" \
    "$SET_CODE_SIGN_IDENTITY"
  /bin/cp -acf "$DERIVED_RELEASE"/AlDente.app ../"$ARCHIVE_APPS"
)

(
  cd ./Transmission
  xcodebuild -scheme Transmission \
    "${FLAG_RELEASE[@]}" \
    "${FLAG_DERIVED_DATA[@]}" \
    "$SET_DEVELOPMENT_TEAM" \
    "$SET_CODE_SIGN_IDENTITY"
  /bin/cp -acf "$DERIVED_RELEASE"/Transmission.app ../"$ARCHIVE_APPS"

  # remove some garbage generated during the build
  git submodule foreach --recursive git clean -fd
)

# # disabled: not working for the moment
# (
#   cd ./Battery-Toolkit
#   xcodebuild -scheme "Battery Toolkit"\
#     "${FLAG_RELEASE[@]}" \
#     "${FLAG_DERIVED_DATA[@]}" \
#     "$SET_DEVELOPMENT_TEAM" \
#     "$SET_CODE_SIGN_IDENTITY" \
#     BT_CODESIGN_CN="Apple Development: bryanlai@foxmail.com (VY3W9R894Q)"
#   /bin/cp -acf "$DERIVED_RELEASE"/"Battery Toolkit".app ../"$ARCHIVE_APPS"
# )

(
  cd ./TeXShop
  patch < ../_patches/TeXShop-fix-build.patch
  xcodebuild -scheme TeXShop \
    "${FLAG_RELEASE[@]}" \
    "${FLAG_DERIVED_DATA[@]}" \
    "$SET_DEVELOPMENT_TEAM" \
    "$SET_CODE_SIGN_IDENTITY"
  /bin/cp -acf "$DERIVED_RELEASE"/TeXShop.app ../"$ARCHIVE_APPS"
  git restore TeXShop.xcodeproj
)

(
  cd ./Amethyst
  patch < ../_patches/Amethyst-dont-lint.patch
  xcodebuild -workspace Amethyst.xcworkspace -scheme Amethyst \
    "${FLAG_RELEASE[@]}" \
    "${FLAG_DERIVED_DATA[@]}" \
    "$SET_DEVELOPMENT_TEAM" \
    "$SET_CODE_SIGN_IDENTITY"
  /bin/cp -acf "$DERIVED_RELEASE"/Amethyst.app ../"$ARCHIVE_APPS"
  git restore Amethyst.xcodeproj
)

(
  cd ./Ice
  xcodebuild -scheme Ice \
    "${FLAG_RELEASE[@]}" \
    "${FLAG_DERIVED_DATA[@]}" \
    "$SET_DEVELOPMENT_TEAM"
  /bin/cp -acf "$DERIVED_RELEASE"/Ice.app ../"$ARCHIVE_APPS"
)

(
  cd ./Maccy
  xcodebuild -scheme Maccy \
    "${FLAG_RELEASE[@]}" \
    "${FLAG_DERIVED_DATA[@]}" \
    "$SET_DEVELOPMENT_TEAM" \
    "$SET_CODE_SIGN_IDENTITY"
  /bin/cp -acf "$DERIVED_RELEASE"/Maccy.app ../"$ARCHIVE_APPS"
)

(
  if ! command -v pod &>/dev/null; then
    >&2 echo "# require cocoapods: brew install cocoapods"
    exit 1
  fi

  cd ./AutoMute
  patch < ../_patches/AutoMute-entitlements.patch
  pod install
  xcodebuild -workspace automute.xcworkspace -scheme AutoMute \
    -allowProvisioningUpdates \
    "${FLAG_RELEASE[@]}" \
    "${FLAG_DERIVED_DATA[@]}" \
    "$SET_DEVELOPMENT_TEAM" \
    "$SET_CODE_SIGN_IDENTITY"
  /bin/cp -acf "$DERIVED_RELEASE"/AutoMute.app ../"$ARCHIVE_APPS"
  git restore 'Pod*' '**.entitlements'
)

(
  cd ./AltTab

  # update version; see:
  # - ./.github/workflows/ci_cd.yml
  # - ./scripts/replace_environment_variables_in_app.sh
  version=$(git describe --tags --match='v*' | sed 's/^v//')
  sed -i '' -e "s/#VERSION#/$version/" Info.plist

  xcodebuild -scheme Release -workspace alt-tab-macos.xcworkspace \
    "${FLAG_DERIVED_DATA[@]}" \
    "$SET_DEVELOPMENT_TEAM" \
    "$SET_CODE_SIGN_IDENTITY" \
    MACOSX_DEPLOYMENT_TARGET=10.13
  /bin/cp -acf "$DERIVED_RELEASE"/AltTab.app ../"$ARCHIVE_APPS"

  git restore Info.plist
)

(
  cd ./MiddleClick
  patch < ../_patches/MiddleClick-dev-team.patch
  make
  /bin/cp -acf ./build/MiddleClick.app ../"$ARCHIVE_APPS"
  git restore Makefile
)

(
  cd ./Rectangle
  xcodebuild -scheme Rectangle \
    "${FLAG_RELEASE[@]}" \
    "${FLAG_DERIVED_DATA[@]}" \
    "$SET_DEVELOPMENT_TEAM"
  /bin/cp -acf "$DERIVED_RELEASE"/Rectangle.app ../"$ARCHIVE_APPS"
)

if ! command -v nix cachix &>/dev/null; then
  >&2 echo "# require nix & cachix for packaging & caching"
  exit 1
fi

nix store add --name "$PNAME" ./_archive > "$STORE_PATH_FILE"
git add --intent-to-add "$STORE_PATH_FILE"
cachix push "$CACHIX_CACHE" "$(cat "$STORE_PATH_FILE")"

# post the store path in github actions
# see: https://docs.github.com/en/actions/writing-workflows/choosing-what-your-workflow-does/workflow-commands-for-github-actions
echo "::notice title=nix-store-patch::$(cat "$STORE_PATH_FILE")"
cat "$STORE_PATH_FILE"
