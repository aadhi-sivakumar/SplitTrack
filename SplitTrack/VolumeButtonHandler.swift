import UIKit
import MediaPlayer
import AVFoundation

class VolumeButtonHandler {
    private var volumeView: MPVolumeView?
    private var volumeObservation: NSKeyValueObservation?
    private var lastVolume: Float = 0.0
    private let volumeChangeHandler: () -> Void

    init(volumeChangeHandler: @escaping () -> Void) {
        self.volumeChangeHandler = volumeChangeHandler
        setupVolumeView()
        observeVolumeChanges()
    }

    private func setupVolumeView() {
        volumeView = MPVolumeView(frame: .zero)
        volumeView?.isHidden = true
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            windowScene.windows.first?.addSubview(volumeView!)
        }
    }

    private func observeVolumeChanges() {
        let audioSession = AVAudioSession.sharedInstance()
        try? audioSession.setActive(true)
        lastVolume = audioSession.outputVolume

        volumeObservation = audioSession.observe(\.outputVolume, options: [.new, .old]) { [weak self] (session, change) in
            guard let self = self else { return }
            if let newVolume = change.newValue, newVolume > self.lastVolume {
                self.volumeChangeHandler()
                self.simulateVolumeChangeIfNeeded(newVolume: newVolume)
            }
            self.lastVolume = change.newValue ?? self.lastVolume
        }
    }

    private func simulateVolumeChangeIfNeeded(newVolume: Float) {
        // If volume is at max, simulate a volume down and then volume up to detect the press
        if newVolume == 1.0 {
            let audioSession = AVAudioSession.sharedInstance()
            audioSession.setVolume(0.9)
            audioSession.setVolume(1.0)
        }
    }

    deinit {
        volumeObservation?.invalidate()
    }
}

private extension AVAudioSession {
    func setVolume(_ volume: Float) {
        let volumeView = MPVolumeView(frame: .zero)
        if let slider = volumeView.subviews.first(where: { $0 is UISlider }) as? UISlider {
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.01) {
                slider.value = volume
            }
        }
    }
}

