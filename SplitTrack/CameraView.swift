import SwiftUI
import UIKit
import AVFoundation

struct CameraView: UIViewControllerRepresentable {
    @Binding var isShown: Bool
    @StateObject private var cameraManager = CameraManager()

    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        var parent: CameraView

        init(parent: CameraView) {
            self.parent = parent
        }

        // Handle cancellation
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true) {
                self.parent.isShown = false
            }
        }

        // Handle media selection (photos or videos)
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let mediaURL = info[.mediaURL] as? URL {
                // Video was recorded, save to Photos app
                UISaveVideoAtPathToSavedPhotosAlbum(mediaURL.path, nil, nil, nil)
            } else if let image = info[.originalImage] as? UIImage {
                // Photo was taken, save to Photos app
                UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
            }
            picker.dismiss(animated: true) {
                self.parent.isShown = false
            }
        }

        // This method will be called when the split button is tapped
        @objc func takeSplit() {
            parent.cameraManager.captureSplit()
        }
    }

    // Create the UIImagePickerController for camera usage
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.mediaTypes = ["public.image", "public.movie"] // Allow both photo and video
        picker.delegate = context.coordinator
        picker.videoQuality = .typeHigh // Set high quality for videos
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {
        // No need to update anything in this case
    }

    func makeCoordinator() -> Coordinator {
        return Coordinator(parent: self)
    }

    // Camera view that includes the split button
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: UIScreen.main.bounds)

        // Set up AVCaptureSession for camera functionality
        cameraManager.setupCamera(in: view) // Now the UIView is available

        // Add split button
        let splitButton = UIButton(type: .custom)
        splitButton.setTitle("Split", for: .normal)
        splitButton.backgroundColor = UIColor.blue
        splitButton.layer.cornerRadius = 10
        splitButton.translatesAutoresizingMaskIntoConstraints = false
        splitButton.addTarget(context.coordinator, action: #selector(context.coordinator.takeSplit), for: .touchUpInside)
        view.addSubview(splitButton)

        // Auto Layout for Split button (bottom-right corner)
        NSLayoutConstraint.activate([
            splitButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            splitButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -20),
            splitButton.widthAnchor.constraint(equalToConstant: 100),
            splitButton.heightAnchor.constraint(equalToConstant: 50)
        ])

        return view
    }
}

// Preview
struct CameraView_Previews: PreviewProvider {
    @State static var isShown = true
    static var previews: some View {
        CameraView(isShown: $isShown)
    }
}

