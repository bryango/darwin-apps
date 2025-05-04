# build mac apps from source

There are many wonderful open source Mac apps, which greatly improve the quality of life for a power user.
Most of them are distributed as `.app` bundles in github releases.
Unfortunately, since [the xz incident](https://en.wikipedia.org/wiki/XZ_Utils_backdoor) I can no longer sleep well while running random release tarballs (let alone binaries) on my machine.
Let's build these apps from source then!

> It would be best if there were a _proper_ package manager that is capable of **building, signing and packaging** `.app` bundles **from source**,
> but I have tried many (including homebrew, nix and macports) and none of them is suitable for the task. Therefore, I have to hand-roll my own
> poor man's package manager for `.app`. That is the purpose of this repo.


## usage

### binaries

Zip archives of `.app` bundles can be found in [Releases](https://github.com/bryango/darwin/releases/).
The build process is transparent and fully automated with:
- the build script [`build.sh`](./build.sh), and
- github actions [`.github/workflows/build.yml`](./.github/workflows/build.yml)

Releases are tagged manually after significant updates, but all binaries are built and published automatically by bots.

> CI also pushes a [nix package](https://gist.github.com/bryango/0057346dbf85981e58518be49d36fc06) to [cachix](https://chezbryan.cachix.org/) for my personal use.
> This is explained in more details in the later sections

### sources

App sources are pulled in as git submodules.
Github renders them nicely in the web ui and one can easily click and jump to the source repository.

For each app, you can go to [`build.sh`](./build.sh) and search for the build instructions for each of these projects, and take whatever you need.
Beware of the GNU GPLv3 license though 😉 I believe in free software!

> I understand that git submodules are infamously annoying, but this is the easiest way to fetch the sources for a poor man's package manager.
> I am sorry...

## build.sh

The entire build (and packaging) process is handled by the monolithic [`build.sh`](./build.sh) script.
One should be able to execute the script locally, provided a properly initialized xcode with an apple account logged in;
please refer to the sections below for more instructions.
However, this may not be what you want as it would build the whole set of packages _for me_.
You should just take whatever apps you need from the repo, and drop the useless ones.

> I know the monolithic build script is a giant ball of spaghetti, but it is convenient for me as I can easily reuse build instructions between projects.
> Again I am sorry...

### code signing

Automatic development code signing will be performed if correct IDs are specified at the top of the script. They can be passed as environment variables as well.

- `DEVELOPMENT_TEAM`: with a properly configured xcode you can get it with:

  ```sh
  defaults read com.apple.dt.Xcode IDEProvisioningTeamByIdentifier # ... and grep for `teamID` in the result.
  ```

- `CODE_SIGN_IDENTITY` (optional): this is set to `"Apple Development"` by default and it should just work. The full identity string can be obtained with:

  ```sh
  security find-identity -v -p codesigning
  ```

### ci

The build script is designed to run on GitHub actions with development certificates, implemented in [`.github/workflows/build.yml`](./.github/workflows/build.yml).
Refer to the official documentation to set up the certificates:
- https://docs.github.com/en/actions/use-cases-and-examples/deploying/installing-an-apple-certificate-on-macos-runners-for-xcode-development

We can ignore provisioning for the moment as that requires a paid account, and it's possible to circumvent it by patching the source code as needed (implemented case by case in the build script).

Additional tokens are required for binary caching with nix and cachix. Please refer to [`.github/workflows/build.yml`](./.github/workflows/build.yml) for the additional details.

## packaging

At the end of [`build.sh`](./build.sh) we attempt to package and cache the build results into a nix archive.
This final phase in [`build.sh`](./build.sh) requires nix and cachix.
This design is very much self-serving as my system configuration is mostly managed by nix.
The store path of the final nix package is pushed to:
- https://gist.github.com/bryango/0057346dbf85981e58518be49d36fc06

So that I can easily refer to it in a nix configuration.
