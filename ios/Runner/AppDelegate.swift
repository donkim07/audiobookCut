import Flutter
import UIKit
import AVFoundation

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    let controller: FlutterViewController = window?.rootViewController as! FlutterViewController
    let audioChannel = FlutterMethodChannel(name: "com.example.audiobookcut/audio",
                                            binaryMessenger: controller.binaryMessenger)
    audioChannel.setMethodCallHandler { (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
      if call.method == "cutAudio" {
        guard let args = call.arguments as? [String: Any],
              let inputPath = args["inputPath"] as? String,
              let outputPath = args["outputPath"] as? String,
              let startMs = args["startMs"] as? Int,
              let endMs = args["endMs"] as? Int else {
          result(FlutterError(code: "INVALID_ARGUMENTS", message: "Invalid arguments", details: nil))
          return
        }
        self.cutAudio(inputPath: inputPath, outputPath: outputPath, startMs: startMs, endMs: endMs, result: result)
      } else {
        result(FlutterMethodNotImplemented)
      }
    }

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  private func cutAudio(inputPath: String, outputPath: String, startMs: Int, endMs: Int, result: @escaping FlutterResult) {
    let startTime = CMTime(value: CMTimeValue(startMs), timescale: 1000)
    let endTime = CMTime(value: CMTimeValue(endMs), timescale: 1000)
    let timeRange = CMTimeRange(start: startTime, end: endTime)
    
    let asset = AVAsset(url: URL(fileURLWithPath: inputPath))
    let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetAppleM4A)
    
    guard exportSession != nil else {
        result(FlutterError(code: "EXPORT_ERROR", message: "Could not create export session", details: nil))
        return
    }
    
    exportSession!.outputURL = URL(fileURLWithPath: outputPath)
    exportSession!.outputFileType = .m4a
    exportSession!.timeRange = timeRange
    
    exportSession!.exportAsynchronously {
        switch exportSession!.status {
        case .completed:
            result(nil)
        case .failed, .cancelled:
            result(FlutterError(code: "EXPORT_FAILED", message: exportSession!.error?.localizedDescription ?? "Export failed", details: nil))
        default:
            result(FlutterError(code: "UNKNOWN_ERROR", message: "Unknown export error", details: nil))
        }
    }
  }
}
