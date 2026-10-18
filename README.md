# ImageOptim

[ImageOptim](https://imageoptim.com) is a GUI for lossless image optimization tools: Zopfli, PNGOUT, [OxiPNG](https://lib.rs/crates/oxipng), AdvPNG, PNGCrush, [JPEGOptim](https://github.com/tjko/jpegoptim), Jpegtran, [Guetzli](https://github.com/google/guetzli), [Gifsicle](https://kornel.ski/lossygif), [SVGO](https://github.com/svg/svgo), [svgcleaner](https://github.com/RazrFalcon/svgcleaner) and [MozJPEG](https://github.com/mozilla/mozjpeg).

## Building

Requires:

* Xcode with Swift 6.2 or later support
* macOS 14 or later to run the SwiftUI app
* [Rust](https://rust-lang.org/) installed via [rustup](https://www.rustup.rs/) (not Homebrew).

```sh
git clone --recursive https://imageoptim.com ImageOptim
cd ImageOptim
```

To get started, initialize submodules with `git submodule update --init --recursive` and open `ImageOptim.xcodeproj`
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

SVGO is pinned in `svgo/package-lock.json` and built with `npm ci`; the build and runtime require Node.js 16 or newer
The Swift backend locates Node.js in the standard installation directories or the app’s inherited PATH
Run `make -C svgo && npm --prefix svgo test` to check both SVG modes and the bundled script
Run `python3 -B scripts/test-tool-versions.py` for offline version-checker tests

The updated native tools are built by the existing Xcode targets
AdvanceCOMP and PNGCrush archives are versioned and checksum-verified during source preparation
Gifsicle uses upstream's integrated lossy compression
For local ad hoc validation of tools that load bundled libraries, build with `ENABLE_HARDENED_RUNTIME=NO`; distribution builds require a shared signing identity

## Interface

The main app uses SwiftUI for its window, sortable results table, toolbar, menus, Quick Look, and settings
The app lifecycle, file list, folder scanner, scripting command, shared preferences, and action extension are implemented in Swift 6
The Swift 6 optimization engine schedules bundled command-line tools using async tasks, with observable job state, cancellation, result caching, and recoverable file replacement
`imageoptim/SwiftUI` contains the main interface and observable view models
The ImageOptimize action extension uses async image loading and a SwiftUI progress view hosted by a Swift native entry point
The app and extension no longer load XIB files
`ImageOptimController` provides native file-opening, Finder services, update checks, and application lifecycle integration

The root Xcode project contains all optimizer and updater targets, with no nested dependency projects
The navigator groups each source file once under its physical folder

Folder-import regression tests use Swift Testing and run with `scripts/test-swift.sh`, with all build artifacts kept in a temporary directory

The app and backend keep strict compiler diagnostics
Pinned third-party targets use compatibility settings for legacy C, Objective-C, and Rust code, with `-Wall` retained for C and Objective-C
