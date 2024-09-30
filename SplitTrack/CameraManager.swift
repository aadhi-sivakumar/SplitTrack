import SwiftUI
import AVFoundation

class CameraManager: ObservableObject {
    @Published var splits: [String] = []
    var captureSession: AVCaptureSession?
    private var startTime: Date?

    // Set up the camera session
    func setupCamera(in view: UIView) {
        captureSession = AVCaptureSession()
        guard let captureSession = captureSession else { return }

        captureSession.beginConfiguration()

        // Set up video input from the camera
        guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let videoInput = try? AVCaptureDeviceInput(device: videoDevice) else {
            return
        }
        if captureSession.canAddInput(videoInput) {
            captureSession.addInput(videoInput)
        }

        // Set up the preview layer to show the camera feed
        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.frame = view.bounds
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)

        captureSession.commitConfiguration()
        captureSession.startRunning()

        // Start the timer for video recording
        startTime = Date()
    }

    // Stop the camera session
    func stopSession() {
        captureSession?.stopRunning()
        captureSession = nil
        splits.removeAll()
    }

    // Capture a split time during video recording
    func captureSplit() {
        guard let startTime = startTime else { return }
        let elapsedTime = Date().timeIntervalSince(startTime)
        let splitTime = String(format: "%.2f seconds", elapsedTime)
        splits.append(splitTime)
    }
}

