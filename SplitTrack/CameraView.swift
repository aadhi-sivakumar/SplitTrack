import SwiftUI
import AVFoundation

struct CameraView: UIViewRepresentable {
    @EnvironmentObject var viewModel: ViewModel
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: UIScreen.main.bounds)
        viewModel.setupCameraPreview(on: view)
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {}
}

