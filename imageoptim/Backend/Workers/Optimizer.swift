import Foundation
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers

nonisolated struct Optimizer: Sendable {
    let name: String
    let executable: String
    let quality: Int
    let interlaced: Bool

    init(_ executable: String, name: String, quality: Int = 100, interlaced: Bool = false) {
        self.executable = executable
        self.name = name
        self.quality = quality
        self.interlaced = interlaced
    }

    static func plan(for type: FileType, settings s: OptimizationSettings, repeated: Bool, lossyConverted: Bool) -> [Optimizer] {
        var tools: [Optimizer] = []
        let level = s.level + (repeated ? 1 : 0)
        switch type {
        case .png:
            if s.lossy && !lossyConverted && (31..<100).contains(s.pngQuality) {
                tools.append(Optimizer("pngquant", name: "pngquant", quality: s.pngQuality))
            }
            if s.enabled.contains("PngCrush2") && !(level < 2 && s.enabled.contains("OptiPng")) {
                tools.append(Optimizer("pngcrush", name: "Pngcrush"))
            }
            if s.enabled.contains("OptiPng") { tools.append(Optimizer("oxipng", name: "OxiPNG")) }
            if s.enabled.contains("PngOut") && !(level < 4 && s.enabled.contains("Zopfli")) {
                tools.append(Optimizer("pngout", name: "PNGOUT"))
            }
            if s.enabled.contains("AdvPng") && s.stripPNG { tools.append(Optimizer("advpng", name: "AdvPNG")) }
            if s.enabled.contains("Zopfli") { tools.append(Optimizer("zopflipng", name: "Zopfli")) }
        case .jpeg:
            if !lossyConverted && !repeated && s.enabled.contains("Guetzli") && s.jpegQuality >= 80 {
                tools.append(Optimizer("guetzli", name: "Guetzli", quality: max(84, s.lossy ? s.jpegQuality : 95)))
            }
            if s.enabled.contains("JpegOptim") {
                let quality = s.lossy ? s.jpegQuality : 100
                tools.append(Optimizer("jpegoptim", name: quality < 100 ? "JpegOptim \(quality)%" : "JpegOptim", quality: quality))
            }
            if s.enabled.contains("JpegTran") { tools.append(Optimizer("jpegtran", name: "MozJPEG")) }
        case .gif:
            if s.enabled.contains("Gifsicle") {
                if s.lossy && !lossyConverted && (31..<100).contains(s.gifQuality) {
                    tools.append(Optimizer("gifsicle", name: "Giflossy", quality: s.gifQuality))
                } else {
                    tools.append(Optimizer("gifsicle", name: "Gifsicle"))
                    if level > 1 { tools.append(Optimizer("gifsicle", name: "Gifsicle interlaced", interlaced: true)) }
                }
            }
        case .svg:
            if s.enabled.contains("Svgo") { tools.append(Optimizer("svgo", name: s.lossy ? "SVGO" : "SVGO lite")) }
            if s.enabled.contains("Svgcleaner") { tools.append(Optimizer("svgcleaner", name: "Svgcleaner")) }
        }
        return tools
    }

    @MainActor
    func optimize(_ file: File, output: URL, settings s: OptimizationSettings, repeated: Bool, runner: CommandWorker) async throws -> File? {
        let level = s.level + (repeated ? 1 : 0)
        let timeLimit = min(8 + level * 13, 10 + Int(file.byteSize / 1024))
        var arguments: [String]
        var input: URL?
        var stdout: URL?
        var timeout: Int?
        var executableURL: URL
        if executable == "svgo" {
            let searchPaths = (ProcessInfo.processInfo.environment["PATH"] ?? "").split(separator: ":").map { URL(filePath: String($0)).appending(path: "node").path }
            let candidates = ["/usr/local/bin/node", "/opt/homebrew/bin/node"] + searchPaths
            guard let script = Bundle(for: BundleAnchor.self).url(forResource: "svgo", withExtension: "js"),
                  let node = candidates.first(where: { FileManager.default.isExecutableFile(atPath: $0) }) else {
                throw CocoaError(.executableNotLoadable, userInfo: [NSLocalizedDescriptionKey: "SVGO requires Node.js and its bundled script"])
            }
            executableURL = URL(filePath: node)
            arguments = [script.path, s.lossy ? "1" : "0", file.path.path, output.path]
        } else {
            executableURL = try CommandWorker.executable(executable)
            switch executable {
            case "advpng":
                try await FileOperations.copy(file.path, to: output)
                arguments = ["-\(max(1, min(4, level)))", "-z", "--", output.path]
            case "oxipng":
                arguments = (s.stripPNG ? ["--strip=safe"] : []) + ["-o2", "-i0", "-a", "--out", output.path, "--", file.path.path]
            case "pngcrush":
                arguments = (s.stripPNG ? ["-rem", "alla"] : []) + ["-nofilecheck", "-bail", "-blacken", "-reduce", "-cc", "--", file.path.path, output.path]
                if file.isSmall || (level >= 6 && !file.isLarge) { arguments.insert("-brute", at: 0) }
            case "pngout":
                var speed = level == 0 ? 2 : (level >= 4 ? 0 : 1)
                if file.isLarge && speed < 2 { speed += 1 }
                arguments = (s.stripPNG ? [] : ["-k1"]) + ["-s\(speed)", "-r", "-v", file.path.path, "-"]
                stdout = output
                timeout = timeLimit
            case "pngquant":
                arguments = ["256", "--skip-if-larger", "-s\(max(1, min(3, 7 - level)))", "--quality", "\(quality)-\(min(100, quality + 20))", "-"]
                input = file.path
                stdout = output
            case "zopflipng":
                var iterations = 3 + 3 * level
                if file.isLarge { iterations = 5 + iterations / 3 }
                let filters = repeated ? "bp" : (file.isLarge ? "p" : "0pme")
                arguments = ["--timelimit=\(Int(Double(timeLimit) * (repeated ? 1.4 : 0.8)))", "--iterations=\(iterations)", "--filters=\(filters)"]
                if !s.stripPNG { arguments.append("--keepchunks=tEXt,zTXt,iTXt,gAMA,sRGB,iCCP,bKGD,pHYs,sBIT,tIME,oFFs,acTL,fcTL,fdAT,prVW,mkBF,mkTS,mkBS,mkBT") }
                arguments += ["--lossy_transparent", "-y", file.path.path, output.path]
            case "jpegoptim":
                try await FileOperations.copy(file.path, to: output)
                let lossy = (11..<100).contains(quality)
                arguments = (lossy ? ["-m\(quality)"] : []) + [s.stripJPEG ? "--strip-all" : "--strip-none", lossy ? "--all-progressive" : "--all-normal", "-v", "--", output.path]
            case "jpegtran":
                arguments = ["-copy", s.stripJPEG ? "none" : "all", "-optimize", "-outfile", output.path, file.path.path]
            case "gifsicle":
                arguments = ["-o", output.path, interlaced ? "--interlace" : "--no-interlace", "-O3", "--careful", "--no-comments", "--no-names", "--same-delay", "--same-loopcount", "--no-warnings", "--", file.path.path]
                if quality < 100 {
                    var loss = Int(pow(Double(100 - quality), 1.8) / 5)
                    if file.isSmall { loss = 1 + loss / 8 } else if !file.isLarge { loss = 1 + loss / 2 }
                    arguments.insert("--lossy=\(loss)", at: 0)
                }
            case "svgcleaner":
                arguments = ["--stdout", "--", file.path.path]
                stdout = output
            case "guetzli":
                try await Self.convertToSRGB(file.path, output: output)
                arguments = ["--quality", "\(quality)", "--memlimit", file.isSmall ? "2000" : "6000", output.path, output.path]
            default:
                throw CocoaError(.executableNotLoadable)
            }
        }
        let status = try await runner.run(executable: executableURL, arguments: arguments, input: input, output: stdout, timeout: timeout, lowPriority: s.lowPriority)
        try Task.checkCancellation()
        guard status == 0 || (executable == "pngquant" && [98, 99].contains(status)) || (executable == "pngout" && status == 2) else {
            throw CocoaError(.executableRuntimeMismatch, userInfo: [NSLocalizedDescriptionKey: "\(name) exited with status \(status)"])
        }
        guard let result = try? await FileOperations.read(output), result.fileType == file.fileType, result.byteSize < file.byteSize else { return nil }
        if ["pngcrush", "zopflipng"].contains(executable) && result.byteSize <= 70 { return nil }
        if executable == "jpegoptim" && quality < 100 && Double(result.byteSize) >= Double(file.byteSize) * 0.95 { return nil }
        if executable == "gifsicle" && quality < 100 && result.byteSize * UInt(105 + (100 - quality) / 2) / 100 >= file.byteSize { return nil }
        return result
    }

    @concurrent
    private static func convertToSRGB(_ input: URL, output: URL) async throws {
        guard let source = CGImageSourceCreateWithURL(input as CFURL, nil),
              let image = CGImageSourceCreateImageAtIndex(source, 0, nil),
              let space = CGColorSpace(name: CGColorSpace.sRGB),
              let context = CGContext(data: nil, width: image.width, height: image.height, bitsPerComponent: 8, bytesPerRow: 0, space: space, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { throw CocoaError(.fileReadCorruptFile) }
        context.setRenderingIntent(.relativeColorimetric)
        context.draw(image, in: CGRect(x: 0, y: 0, width: image.width, height: image.height))
        guard let converted = context.makeImage(),
              let destination = CGImageDestinationCreateWithURL(output as CFURL, UTType.png.identifier as CFString, 1, nil) else { throw CocoaError(.fileWriteUnknown) }
        CGImageDestinationAddImage(destination, converted, nil)
        guard CGImageDestinationFinalize(destination) else { throw CocoaError(.fileWriteUnknown) }
    }
}
