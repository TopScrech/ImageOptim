#!/bin/sh
set -eu
project_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
test_workspace=$(mktemp -d "${TMPDIR:-/tmp}/ImageOptim-swift-tests.XXXXXX")
trap 'rm -rf "$test_workspace"' EXIT HUP INT TERM
mkdir -p "$test_workspace/Sources/ImageOptimImport" "$test_workspace/Tests/ImageOptimImportTests"
cp "$project_root/imageoptim/SwiftUI/Optimization/DirectoryScanner.swift" "$test_workspace/Sources/ImageOptimImport/"
cp "$project_root/imageoptim/Tests/DirectoryScannerTests.swift" "$test_workspace/Tests/ImageOptimImportTests/"
cat > "$test_workspace/Package.swift" <<'PACKAGE'
// swift-tools-version: 6.2
import PackageDescription
let package = Package(
    name: "ImageOptimImport",
    platforms: [.macOS(.v14)],
    targets: [
        .target(name: "ImageOptimImport", swiftSettings: [.defaultIsolation(MainActor.self)]),
        .testTarget(name: "ImageOptimImportTests", dependencies: ["ImageOptimImport"])
    ]
)
PACKAGE
swift test --package-path "$test_workspace" --scratch-path "$test_workspace/build"
