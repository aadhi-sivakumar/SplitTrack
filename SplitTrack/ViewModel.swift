import SwiftUI
import AVFoundation
import Photos

enum CameraError: Error {
    case cameraUnavailable
    case inputAdditionFailed
    case outputAdditionFailed
    case outputUnavailable
}

class ViewModel: NSObject, ObservableObject {
    @Published var isRecording = false
    @Published var splits: [Split] = []
    @Published var useFrontCamera = false
    
    private var captureSession: AVCaptureSession?
    private var videoOutput: AVCaptureMovieFileOutput?
    private var timer: Timer?
    private var startTime: Date?
    private var volumeButtonHandler: VolumeButtonHandler?
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private var totalElapsedTime: TimeInterval = 0
    var currentZoomFactor: CGFloat = 1.0
    private let maxZoomFactor: CGFloat = 5.0
    
    override init() {
        super.init()
        volumeButtonHandler = VolumeButtonHandler { [weak self] in
            DispatchQueue.main.async {
                self?.recordSplit()
            }
        }
    }
    
    func setupCameraPreview(on view: UIView) {
        captureSession = AVCaptureSession()
        captureSession?.sessionPreset = .high
        configureCamera(for: captureSession!)
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession!)
        previewLayer?.frame = view.bounds
        previewLayer?.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer!)
        captureSession?.startRunning()
    }
    
    func configureCamera(for session: AVCaptureSession) {
        session.beginConfiguration()
        session.inputs.forEach { input in
            session.removeInput(input)
        }
        
        let camera = useFrontCamera ? AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) : AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back)
        
        do {
            guard let videoDevice = camera else { throw CameraError.cameraUnavailable }
            let videoInput = try AVCaptureDeviceInput(device: videoDevice)
            guard session.canAddInput(videoInput) else { throw CameraError.inputAdditionFailed }
            
            session.addInput(videoInput)
            
            videoOutput = AVCaptureMovieFileOutput()
            if let videoOutput = videoOutput, session.canAddOutput(videoOutput) {
                session.addOutput(videoOutput)
            } else {
                throw CameraError.outputAdditionFailed
            }
            session.commitConfiguration()
        } catch {
            handleError(error)
        }
    }
    
    func startRecording() {
        guard let videoOutput = videoOutput else {
            handleError(CameraError.outputUnavailable)
            return
        }
        let outputPath = NSTemporaryDirectory() + UUID().uuidString + ".mov"
        let outputFileURL = URL(fileURLWithPath: outputPath)
        videoOutput.startRecording(to: outputFileURL, recordingDelegate: self)
        isRecording = true
        startTime = Date()
        splits.removeAll()
        totalElapsedTime = 0
        startTimer()
    }
    
    func stopRecording() {
        guard let videoOutput = videoOutput else {
            handleError(CameraError.outputUnavailable)
            return
        }
        videoOutput.stopRecording()
        isRecording = false
        stopTimer()
    }
    
    func toggleCamera() {
        useFrontCamera.toggle()
        guard let captureSession = captureSession else { return }
        configureCamera(for: captureSession)
    }
    
    private func recordSplit() {
        guard isRecording, let startTime = startTime else { return }
        let currentTime = Date()
        let splitTime = currentTime.timeIntervalSince(startTime)
        self.startTime = currentTime // Restart the split time
        totalElapsedTime += splitTime
        let split = Split(time: splitTime, totalElapsedTime: totalElapsedTime)
        splits.append(split)
    }
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            self.objectWillChange.send()
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    private func saveVideoToPhotos(url: URL) {
        PHPhotoLibrary.requestAuthorization { status in
            guard status == .authorized else { return }
            PHPhotoLibrary.shared().performChanges({
                PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: url)
            }) { success, error in
                if success {
                    print("Video saved to Photos")
                } else if let error = error {
                    print("Error saving video to Photos: \(error)")
                }
            }
        }
    }
    
    func setupOrientationObserver() {
        NotificationCenter.default.addObserver(self, selector: #selector(handleOrientationChange), name: UIDevice.orientationDidChangeNotification, object: nil)
        UIDevice.current.beginGeneratingDeviceOrientationNotifications()
    }
    
    func removeOrientationObserver() {
        NotificationCenter.default.removeObserver(self, name: UIDevice.orientationDidChangeNotification, object: nil)
        UIDevice.current.endGeneratingDeviceOrientationNotifications()
    }
    
    @objc private func handleOrientationChange() {
        objectWillChange.send()
        // Additional handling if needed
    }
    
    private func handleError(_ error: Error) {
        print("Error: \(error)")
    }
    
    func setZoom(factor: CGFloat) {
        guard let device = useFrontCamera ? AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) : AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else { return }
        
        do {
            try device.lockForConfiguration()
            device.videoZoomFactor = max(1.0, min(factor, maxZoomFactor))
            device.unlockForConfiguration()
            currentZoomFactor = device.videoZoomFactor
        } catch {
            print("Failed to set zoom factor: \(error)")
        }
    }
    
    func currentOrientationAngle(_ geometry: GeometryProxy) -> Double {
        let angle: Double
        switch UIDevice.current.orientation {
        case .portrait:
            angle = 0
        case .portraitUpsideDown:
            angle = 180
        case .landscapeLeft:
            angle = -90
        case .landscapeRight:
            angle = 90
        default:
            angle = 0
        }
        
        return angle
    }
}

extension ViewModel: AVCaptureFileOutputRecordingDelegate {
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        if error == nil {
            saveVideoToPhotos(url: outputFileURL)
        } else {
            print("Error recording video: \(String(describing: error))")
        }
    }
}

struct Split: Identifiable {
    let id = UUID()
    let time: TimeInterval
    let totalElapsedTime: TimeInterval
    
    var timeString: String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        let milliseconds = Int((time - TimeInterval(minutes * 60) - TimeInterval(seconds)) * 100)
        return String(format: "%02d:%02d.%02d", minutes, seconds, milliseconds)
    }
    
    var totalElapsedTimeString: String {
        return formatTime(totalElapsedTime)
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = time.truncatingRemainder(dividingBy: 60)
        return String(format: "%02d:%05.2f", minutes, seconds)
    }
}

