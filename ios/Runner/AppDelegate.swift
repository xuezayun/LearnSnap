import Flutter
import UIKit
import Vision

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    let ok = super.application(application, didFinishLaunchingWithOptions: launchOptions)
    if let controller = window?.rootViewController as? FlutterViewController {
      let channel = FlutterMethodChannel(
        name: "learnsnap/platform",
        binaryMessenger: controller.binaryMessenger
      )
      channel.setMethodCallHandler { call, result in
        if call.method == "recognizeText" {
          IosTextRecognizer.handle(call: call, result: result)
        } else {
          result(FlutterMethodNotImplemented)
        }
      }
    }
    return ok
  }
}

enum IosTextRecognizer {
  static func handle(call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String: Any],
          let typed = args["bytes"] as? FlutterStandardTypedData else {
      result(FlutterError(code: "ARG", message: "bytes required", details: nil))
      return
    }
    let english = (args["lang"] as? String) == "en"
    let bytes = typed.data
    DispatchQueue.global(qos: .userInitiated).async {
      do {
        let lines = try recognize(bytes: bytes, english: english)
        DispatchQueue.main.async { result(lines) }
      } catch {
        DispatchQueue.main.async {
          result(FlutterError(code: "OCR", message: error.localizedDescription, details: nil))
        }
      }
    }
  }

  private static func recognize(bytes: Data, english: Bool) throws -> [[String: Any]] {
    guard let source = UIImage(data: bytes) else { return [] }
    let image = downscaled(source, maxSide: 1600)
    guard let cg = image.cgImage else { return [] }
    let request = VNRecognizeTextRequest()
    request.recognitionLevel = .accurate
    request.usesLanguageCorrection = false
    request.recognitionLanguages = english ? ["en-US"] : ["zh-Hans", "en-US"]
    let handler = VNImageRequestHandler(cgImage: cg, orientation: .up, options: [:])
    try handler.perform([request])
    let width = CGFloat(cg.width)
    let height = CGFloat(cg.height)
    var lines: [[String: Any]] = []
    for observation in request.results ?? [] {
      guard let candidate = observation.topCandidates(1).first else { continue }
      let words = wordBoxes(candidate: candidate, imageWidth: width, imageHeight: height)
      if words.isEmpty {
        let text = candidate.string.trimmingCharacters(in: .whitespacesAndNewlines)
        if text.isEmpty { continue }
        let box = observation.boundingBox
        let left = box.origin.x * width
        let top = (1 - box.origin.y - box.size.height) * height
        lines.append([
          "text": text,
          "left": Double(left),
          "top": Double(top),
          "right": Double(left + box.size.width * width),
          "bottom": Double(top + box.size.height * height),
        ])
      } else {
        lines.append(contentsOf: words)
      }
    }
    return lines
  }

  /// One box per word. A printed space splits the line even when it is narrow
  /// and the recognizer did not write a space character into the string.
  private static func wordBoxes(
    candidate: VNRecognizedText,
    imageWidth: CGFloat,
    imageHeight: CGFloat
  ) -> [[String: Any]] {
    struct Glyph {
      let ch: Character
      let box: CGRect
    }
    var glyphs: [Glyph] = []
    var index = candidate.string.startIndex
    while index < candidate.string.endIndex {
      let next = candidate.string.index(after: index)
      let ch = candidate.string[index]
      if let obs = try? candidate.boundingBox(for: index..<next) {
        let n = obs.boundingBox
        glyphs.append(Glyph(
          ch: ch,
          box: CGRect(
            x: n.origin.x * imageWidth,
            y: (1 - n.origin.y - n.height) * imageHeight,
            width: n.width * imageWidth,
            height: n.height * imageHeight
          )
        ))
      }
      index = next
    }
    if glyphs.isEmpty { return [] }
    let widths = glyphs.map(\.box.width).filter { $0 > 1 }
    let charWidth = widths.isEmpty ? 12 : widths.reduce(0, +) / CGFloat(widths.count)
    let gapLimit = max(4, charWidth * 0.22)
    var lines: [[String: Any]] = []
    var chunk: [Glyph] = []

    func flush() {
      let kept = chunk.filter { !$0.ch.isWhitespace }
      chunk = []
      guard !kept.isEmpty else { return }
      let left = kept.map(\.box.minX).min() ?? 0
      let top = kept.map(\.box.minY).min() ?? 0
      let right = kept.map(\.box.maxX).max() ?? left
      let bottom = kept.map(\.box.maxY).max() ?? top
      lines.append([
        "text": String(kept.map(\.ch)),
        "left": Double(left),
        "top": Double(top),
        "right": Double(right),
        "bottom": Double(bottom),
      ])
    }

    for glyph in glyphs {
      if glyph.ch.isWhitespace {
        flush()
        continue
      }
      if let prev = chunk.last(where: { !$0.ch.isWhitespace }) {
        let gap = glyph.box.minX - prev.box.maxX
        if gap >= gapLimit {
          flush()
        }
      }
      chunk.append(glyph)
    }
    flush()
    return lines
  }

  private static func downscaled(_ image: UIImage, maxSide: CGFloat) -> UIImage {
    let size = image.size
    let longest = max(size.width, size.height)
    let target = longest > maxSide && longest > 0
      ? CGSize(width: size.width * maxSide / longest, height: size.height * maxSide / longest)
      : size
    let format = UIGraphicsImageRendererFormat()
    format.scale = 1
    format.opaque = true
    return UIGraphicsImageRenderer(size: target, format: format).image { _ in
      image.draw(in: CGRect(origin: .zero, size: target))
    }
  }
}
