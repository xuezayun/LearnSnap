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
      guard let text = observation.topCandidates(1).first?.string.trimmingCharacters(in: .whitespacesAndNewlines),
            !text.isEmpty else { continue }
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
    }
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
