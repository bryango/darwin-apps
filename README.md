# build mac apps from source

There are many wonderful open source Mac apps that will greatly improve the quality of life of a power user.
Unfortunately, since the xz incident I can no longer sleep well while running random release tarballs (let alone binaries) on my machine. Let's build these apps from source then!

# sources

The git sources are pulled in as submodules (I know, I'm sorry...) and listed in the .gitmodules file.

# build.sh

The build is handled by the monolithic build.sh script. One should be able to run the script locally, provided a properly initialized xcode with an apple account logged in. Automatic development code signing will be performed if correct credentials are specified at the top of build.sh.

The build script is designed to run on GitHub actions with development certificates.

At the end of build.sh we will attempt to package and cache the build results into a nix archive:

# packaging

This phase in build.sh requires nix and cachix.