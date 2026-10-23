# PicPress

PicPress is a macOS app based on [ImageOptim](https://imageoptim.com), providing a GUI for lossless image optimization tools: Zopfli, PNGOUT, [OxiPNG](https://lib.rs/crates/oxipng), AdvPNG, PNGCrush, [JPEGOptim](https://github.com/tjko/jpegoptim), Jpegtran, [Guetzli](https://github.com/google/guetzli), [Gifsicle](https://kornel.ski/lossygif), [SVGO](https://github.com/svg/svgo), [svgcleaner](https://github.com/RazrFalcon/svgcleaner) and [MozJPEG](https://github.com/mozilla/mozjpeg)

## Building

Requires Xcode with Swift 6.2 or later support and macOS 14 or later

```sh
git clone https://github.com/TopScrech/PicPress.git
cd PicPress
open PicPress.xcodeproj
```

The project builds only the Swift app, backend framework, action extension, and tests
Optimizer tools are prebuilt universal macOS executables in `Tools`, supporting Apple silicon and Intel
There are no Git submodules or vendor source builds, and Rust, npm, and C/C++ tool builds are not required
Configure the app and action extension with the same signing team
Debug builds use debugger entitlements; Release builds keep debugger access disabled

`scripts/bundle-sandbox-helpers.sh` verifies `Tools/SHA256SUMS`, copies the executables and their runtime libraries into the backend framework, and signs the embedded tools with sandbox inheritance
SVGO uses the prebuilt `Tools/svgo.js` bundle with Node.js 22.23.4 and JIT disabled
The first build downloads checksum-verified official Node archives for both architectures into DerivedData
The app requires no Node installation or network access at runtime

## Tool repositories

| Tool | Repository | Bundled source |
| --- | --- | --- |
| AdvPNG / AdvanceCOMP | [amadvance/advancecomp](https://github.com/amadvance/advancecomp) | AdvanceCOMP with PicPress compatibility patches |
| Gifsicle | [kohler/gifsicle](https://github.com/kohler/gifsicle) | Upstream, including lossy GIF compression |
| Guetzli | [google/guetzli](https://github.com/google/guetzli) | Upstream with a PicPress compiler patch |
| JPEGOptim | [tjko/jpegoptim](https://github.com/tjko/jpegoptim) | Upstream |
| jpegtran / MozJPEG | [mozilla/mozjpeg](https://github.com/mozilla/mozjpeg) | [ImageOptim/mozjpeg-cocoa](https://github.com/ImageOptim/mozjpeg-cocoa) fork |
| OxiPNG | [oxipng/oxipng](https://github.com/oxipng/oxipng) | Upstream |
| PNGCrush | [PMT pngcrush branch](https://sourceforge.net/p/pmt/code/ci/pngcrush/tree/) | Official source release with a PicPress compatibility patch |
| PNGOUT | No public source repository | [Official macOS binaries](https://www.jonof.id.au/kenutils.html) |
| pngquant | [kornelski/pngquant](https://github.com/kornelski/pngquant) | Upstream with a PicPress Rust manifest patch |
| svgcleaner | [RazrFalcon/svgcleaner](https://github.com/RazrFalcon/svgcleaner) | Upstream with an explicit Rust edition |
| SVGO | [svg/svgo](https://github.com/svg/svgo) | Prebuilt bundle with the PicPress wrapper |
| ZopfliPNG | [google/zopfli](https://github.com/google/zopfli) | [ImageOptim/zopfli](https://github.com/ImageOptim/zopfli) fork with a PicPress compiler patch |
| Node.js | [nodejs/node](https://github.com/nodejs/node) | Official runtime binaries for SVGO |

Supporting image and compression libraries include [libpng](https://github.com/pnggroup/libpng), [zlib](https://github.com/madler/zlib), and [libimagequant](https://github.com/ImageOptim/libimagequant)
Exact bundled tool versions and source revisions are recorded in `Tools/versions.json`

## Optimization tool versions

`Tools/versions.json` records the bundled tool versions and source revisions
Run `python3 scripts/check-tool-versions.py` to compare the manifest with upstream stable releases
The audit requires Python 3.9+ and curl and makes no dependency changes

- `--json` prints versions, source revisions, upstream URLs, and lookup errors
- `--check` exits with status 1 when updates are available
- Incomplete audits exit with status 2

Run `python3 -B scripts/test-tool-versions.py` for offline version-checker tests
To update tools, prepare universal Release executables outside this repository, replace the files in `Tools`, and update the manifest, license notices, and SHA-256 checksums
Keep the ImageOptim fork's CLI compatibility, particularly Zopfli's `--timelimit` option
Keep `libimageoptimjpeg.dylib` and `liblibpng.dylib` alongside the executables that load them
License notices are retained in `Tools/Licenses` and copied into the app

## Interface

The main app uses SwiftUI for its window, sortable results table, toolbar, menus, Quick Look, and settings
The app lifecycle, file list, folder scanner, scripting command, shared preferences, and action extension are implemented in Swift 6
The Swift 6 optimization engine schedules bundled command-line tools using async tasks, with observable job state, cancellation, result caching, and recoverable file replacement
`PicPress/SwiftUI` contains the main interface and observable view models
The ImageOptimize action extension uses async image loading and a SwiftUI progress view hosted by a Swift native entry point
The app and extension no longer load XIB files
`PicPressController` provides native file-opening, Finder services, update checks, and application lifecycle integration

The root Xcode project contains the app, backend, action extension, and test targets
The navigator groups each source file once under its physical folder

Folder-import regression tests use Swift Testing and run with `scripts/test-swift.sh`, with all build artifacts kept in a temporary directory

The app and backend keep strict compiler diagnostics
Prebuilt CLI tools are validated and signed during bundling

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
