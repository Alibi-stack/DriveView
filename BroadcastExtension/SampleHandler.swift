import CoreImage
import CoreMedia
import ImageIO
import ReplayKit

final class SampleHandler: RPBroadcastSampleHandler {
    private let context = CIContext(options: [.cacheIntermediates: false])
    private let encodeQueue = DispatchQueue(
        label: "com.alibistack.driveview.mirror-encoder",
        qos: .userInteractive
    )
    private let inFlight = DispatchSemaphore(value: 1)

    private var lastFrameTime = CMTime.invalid
    private var lastStatusWrite = Date.distantPast

    private var longEdge = MirrorShared.defaultLongEdge
    private var framesPerSecond = MirrorShared.defaultFramesPerSecond
    private var jpegQuality = MirrorShared.defaultJPEGQuality

    override func broadcastStarted(withSetupInfo setupInfo: [String: NSObject]?) {
        let defaults = MirrorShared.defaults
        let configuredLongEdge = defaults.integer(forKey: MirrorShared.longEdgeKey)
        let configuredFPS = defaults.integer(forKey: MirrorShared.framesPerSecondKey)
        let configuredQuality = defaults.double(forKey: MirrorShared.jpegQualityKey)

        longEdge = configuredLongEdge > 0
            ? min(max(configuredLongEdge, 480), 1920)
            : MirrorShared.defaultLongEdge
        framesPerSecond = configuredFPS > 0
            ? min(max(configuredFPS, 5), 24)
            : MirrorShared.defaultFramesPerSecond
        jpegQuality = configuredQuality > 0
            ? min(max(configuredQuality, 0.45), 0.9)
            : MirrorShared.defaultJPEGQuality

        removePreviousSessionFiles()
    }

    override func broadcastPaused() {}

    override func broadcastResumed() {
        lastFrameTime = .invalid
    }

    override func broadcastFinished() {
        writeStatus(width: 0, height: 0, active: false)
    }

    override func processSampleBuffer(
        _ sampleBuffer: CMSampleBuffer,
        with sampleBufferType: RPSampleBufferType
    ) {
        guard sampleBufferType == .video,
              CMSampleBufferDataIsReady(sampleBuffer),
              let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)
        else { return }

        let presentationTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
        if lastFrameTime.isValid {
            let elapsed = CMTimeGetSeconds(
                CMTimeSubtract(presentationTime, lastFrameTime)
            )
            guard elapsed >= 1.0 / Double(framesPerSecond) else { return }
        }
        lastFrameTime = presentationTime

        guard inFlight.wait(timeout: .now()) == .success else { return }
        let orientation = videoOrientation(from: sampleBuffer)

        encodeQueue.async { [weak self] in
            guard let self else { return }
            defer { self.inFlight.signal() }
            autoreleasepool {
                self.encode(pixelBuffer: pixelBuffer, orientation: orientation)
            }
        }
    }

    private func encode(
        pixelBuffer: CVPixelBuffer,
        orientation: CGImagePropertyOrientation
    ) {
        guard let frameURL = MirrorShared.frameURL else { return }

        var image = CIImage(cvPixelBuffer: pixelBuffer).oriented(orientation)
        let extent = image.extent.integral
        guard extent.width > 0, extent.height > 0 else { return }

        let sourceLongEdge = max(extent.width, extent.height)
        let scale = min(1, CGFloat(longEdge) / sourceLongEdge)
        if scale < 1 {
            image = image.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
        }

        let scaledExtent = image.extent.integral
        if scaledExtent.origin != .zero {
            image = image.transformed(by: CGAffineTransform(
                translationX: -scaledExtent.origin.x,
                y: -scaledExtent.origin.y
            ))
        }

        let options: [CIImageRepresentationOption: Any] = [
            .lossyCompressionQuality: jpegQuality
        ]
        guard let data = context.jpegRepresentation(
            of: image,
            colorSpace: CGColorSpaceCreateDeviceRGB(),
            options: options
        ) else { return }

        do {
            try data.write(to: frameURL, options: .atomic)
            let outputExtent = image.extent.integral
            writeStatus(
                width: Int(outputExtent.width),
                height: Int(outputExtent.height),
                active: true
            )
        } catch {
            finishBroadcastWithError(error)
        }
    }

    private func videoOrientation(
        from sampleBuffer: CMSampleBuffer
    ) -> CGImagePropertyOrientation {
        guard let value = CMGetAttachment(
            sampleBuffer,
            key: RPVideoSampleOrientationKey as CFString,
            attachmentModeOut: nil
        ) as? NSNumber,
              let orientation = CGImagePropertyOrientation(rawValue: value.uint32Value)
        else { return .up }
        return orientation
    }

    private func writeStatus(width: Int, height: Int, active: Bool) {
        let now = Date()
        if active, now.timeIntervalSince(lastStatusWrite) < 0.5 { return }
        lastStatusWrite = now

        guard let statusURL = MirrorShared.statusURL else { return }
        let status = MirrorStatus(
            updatedAt: active ? now : .distantPast,
            width: width,
            height: height,
            framesPerSecond: framesPerSecond
        )
        guard let data = try? PropertyListEncoder().encode(status) else { return }
        try? data.write(to: statusURL, options: .atomic)
    }

    private func removePreviousSessionFiles() {
        if let frameURL = MirrorShared.frameURL {
            try? FileManager.default.removeItem(at: frameURL)
        }
        if let statusURL = MirrorShared.statusURL {
            try? FileManager.default.removeItem(at: statusURL)
        }
    }
}
