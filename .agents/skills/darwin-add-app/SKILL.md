---
name: add-darwin-app
description: Add, update, or build macOS app submodules. Use when the agent is asked to add a new app, add a Git submodule, wire an app into build.sh, inspect upstream build scripts before running them, preserve existing submodule dirtiness, troubleshoot app signing, or verify archived .app bundles in this darwin-apps repository.
---

# Darwin Add App

## Workflow

Start from the real checkout state:

- Run `git status --short --branch` and inspect recent commits when the user says they made updates.
- Read `build.sh`, `.gitmodules`, and any README notes before deciding where to add the app.
- Preserve unrelated submodule gitlink changes, especially existing dirty app submodules.

Add the source checkout carefully:

- For the nested repo to keep its own `.git/` directory, clone first:
  `git clone --filter=blob:none <url> <AppName>`, then register the existing checkout with `git submodule add <url> <AppName>`.
- If the app is on github, check its latest stable release and checkout to it. Otherwise check if it has release-like tags and switch to the latest release tag. If the tags does not look like stable releases then just use master.
- Verify partial clone state with `git -C <AppName> config --get remote.origin.promisor` and `git -C <AppName> config --get remote.origin.partialclonefilter`.
- If `git submodule add --filter=blob:none` is requested but unsupported by the local Git for `add`, explain that `submodule update` supports filters and use clone-first registration.

Inspect before running upstream code:

- Read the upstream build script, package manifest, lock/resolved files, and any Xcode project build phases.
- Search for risky surfaces with `rg`: `sudo`, `brew`, `curl`, `wget`, `security`, `osascript`, `rm -rf`, `codesign`, `xcodebuild`, `swift build`, `pod install`, `npm`, `token`, `keychain`.
- Stop before running if the script has unexpected credential access, broad destructive cleanup, or installs tools without approval.

Wire the app into `build.sh` using existing conventions:

- Reuse `DEVELOPMENT_TEAM`, `CODE_SIGN_IDENTITY`, `FLAG_RELEASE`, `FLAG_DERIVED_DATA`, `ARCHIVE_APPS`, `DERIVED_RELEASE`, and the `/bin/cp` helper when applicable.
- Put the new app block at the top. Use a temporary `exit 0` to prevent rebuilding existing apps during testing.
- Copy the final `.app` into `"$ARCHIVE_APPS"` for testing.
- Do not leave a temporary `exit 0` in the committed script unless the user explicitly wants an early-exit build.

For manually packaged apps, pass signing variables expected by the upstream script. Example from CodexBar:

```bash
(
  cd ./CodexBar
  APP_TEAM_ID="$DEVELOPMENT_TEAM" \
  APP_IDENTITY="$CODE_SIGN_IDENTITY" \
    ./Scripts/package_app.sh release
  /bin/cp -acf ./CodexBar.app ../"$ARCHIVE_APPS"
)
```

## Signing

Distinguish Xcode automatic signing from direct `codesign`:

- `xcodebuild` targets may participate in automatic signing.
- Manually assembled `.app` bundles usually still need explicit `codesign` for nested frameworks, helpers, app extensions, entitlements, and final bundle sealing.
- Direct `codesign --sign "Apple Development"` requires a valid identity in the keychain. Check with `security find-identity -v -p codesigning`; sandboxed shells may report zero even when an escalated or normal user shell can see identities.
- If no valid identity exists, ask the user to recreate an Apple Development certificate in Xcode Settings -> Accounts -> Manage Certificates.

## Validation

Use a focused validation path before running the full archive:

- `bash -n build.sh`
- Run the smallest targeted build command that exercises the new app. If an early-exit trial is requested, make sure `exit 0` prevents other apps and Nix/Cachix packaging from running.
- Verify the archived app:
  `codesign -dv --verbose=4 _archive/Applications/<AppName>.app`
  `codesign --verify --deep --strict --verbose=2 _archive/Applications/<AppName>.app`
- Finish with `git status --short --branch`, noting staged submodule entries, unstaged script edits, ignored build outputs, and unrelated dirty submodules.
- If the user asks to commit, check recent git logs and commit the changes following conventions.
