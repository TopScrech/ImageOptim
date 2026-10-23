# PicPress

PicPress is a macOS app based on [ImageOptim](https://imageoptim.com), providing a GUI for lossless image optimization tools: Zopfli, PNGOUT, [OxiPNG](https://lib.rs/crates/oxipng), AdvPNG, PNGCrush, [JPEGOptim](https://github.com/tjko/jpegoptim), Jpegtran, [Guetzli](https://github.com/google/guetzli), [Gifsicle](https://kornel.ski/lossygif), [SVGO](https://github.com/svg/svgo), [svgcleaner](https://github.com/RazrFalcon/svgcleaner) and [MozJPEG](https://github.com/mozilla/mozjpeg)

## Building

Requires:

* Xcode with Swift 6.2 or later support
* macOS 14 or later to run the SwiftUI app
* [Rust](https://rust-lang.org/) installed via [rustup](https://www.rustup.rs/) (not Homebrew)

```sh
git clone --recursive https://github.com/TopScrech/PicPress.git
cd PicPress
```

To get started, initialize submodules with `git submodule update --init --recursive` and open `PicPress.xcodeproj`
It builds the app and bundled dependencies from this single project
Local builds use ad hoc signing, so the original author’s developer certificates are not required
Debug builds use separate entitlements that allow Xcode to attach its debugger; Release builds keep debugger access disabled
Local builds disable hardened runtime because ad hoc signatures have no team identity for validating embedded frameworks
Distribution builds must enable hardened runtime and configure the appropriate signing identity, team, and shared app group

In case of build errors, these sometimes help:

```sh
git submodule update --init --recursive
```

```sh
cd gifsicle # or pngquant
make clean
make
```

## Optimization tool versions

Run `python3 scripts/check-tool-versions.py` from any directory to compare this checkout's tool versions with upstream stable releases/tags
The script requires Python 3.9+ and curl, reads source manifests and the SVGO lockfile, and makes no dependency changes
It includes all tools, including dependencies that use patched forks
Matching version numbers indicate the same release base, not identical source code

- `--json` prints versions, source revisions, upstream URLs, and any lookup errors as JSON
- `--check` exits with status 1 when updates are available
- Incomplete audits, including network failures or missing sources, exit with status 2

SVGO is pinned in `svgo/package-lock.json` and its prebuilt bundle is tracked in `svgo/prebuilt`
Normal Xcode builds copy this bundle without installing npm dependencies or running Webpack
SVGO uses bundled Node.js 22.23.4 for both Apple silicon and Intel, with JIT disabled
The backend build downloads the pinned official archives, checks their SHA-256 hashes, and embeds a universal runtime and license notices
Downloads are cached in Xcode DerivedData; the first build requires access to nodejs.org
No Node installation or network access is required when running the app
`scripts/bundle-sandbox-helpers.sh` pins the version and checksums and signs all embedded optimizer executables with sandbox inheritance
Run `make -C svgo && node --test svgo/test.cjs` to check both SVG modes and the bundled script without npm dependencies
After changing SVGO dependencies or its wrapper, run `make -C svgo rebuild` and commit the updated prebuilt files alongside the source and lockfile
This explicit rebuild installs npm dependencies and tests both the source and bundles; `make -C svgo clean` removes the dependencies and copied build output while preserving the prebuilt bundle
Run `python3 -B scripts/test-tool-versions.py` for offline version-checker tests

The updated native tools are built by the existing Xcode targets
AdvanceCOMP and PNGCrush archives are versioned and checksum-verified during source preparation
Gifsicle uses upstream's integrated lossy compression
For local ad hoc validation of tools that load bundled libraries, build with `ENABLE_HARDENED_RUNTIME=NO`; distribution builds require a shared signing identity

## Interface

The main app uses SwiftUI for its window, sortable results table, toolbar, menus, Quick Look, and settings
The app lifecycle, file list, folder scanner, scripting command, shared preferences, and action extension are implemented in Swift 6
The Swift 6 optimization engine schedules bundled command-line tools using async tasks, with observable job state, cancellation, result caching, and recoverable file replacement
`PicPress/SwiftUI` contains the main interface and observable view models
The ImageOptimize action extension uses async image loading and a SwiftUI progress view hosted by a Swift native entry point
The app and extension no longer load XIB files
`PicPressController` provides native file-opening, Finder services, update checks, and application lifecycle integration

The root Xcode project contains all optimizer and updater targets, with no nested dependency projects
The navigator groups each source file once under its physical folder

Folder-import regression tests use Swift Testing and run with `scripts/test-swift.sh`, with all build artifacts kept in a temporary directory

The app and backend keep strict compiler diagnostics
Pinned third-party targets use compatibility settings for legacy C, Objective-C, and Rust code, with `-Wall` retained for C and Objective-C

## App Sandbox and App Store builds

The app and action extension enable App Sandbox in Debug and Release
The app requests read/write access to user-selected files and retains security-scoped access for folder scanning, optimization, preview, and undo
Optimizer processes receive copies in the app container rather than paths to user documents
Originals are replaced by the app, and recovery copies are retained under its container's `Library/Application Support/ImageOptim/Recovery`
Reverting removes the corresponding recovery copy; remaining copies can be recovered manually after a crash or app restart
Command-line paths alone do not grant sandbox access; use the file importer, Finder Open With, or drag and drop

Set `DEVELOPMENT_TEAM`, distribution signing identities and provisioning profiles for the app and extension before archiving for App Store submission
`IMAGEOPTIM_APP_GROUP` defaults to `$(TeamIdentifierPrefix)net.pornel.ImageOptim` and is shared by both entitlements and preference storage
Register that app group for your team, or override the setting with your registered group identifier
Local ad hoc builds do not validate provisioning or cross-process app-group access
Distribution builds must set `ENABLE_HARDENED_RUNTIME=YES` consistently across targets
Embedded Node runs with `--jitless` and does not request JIT or unsigned executable-memory entitlements
