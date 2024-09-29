import SwiftUI
import UIKit
import Photos

struct CameraView: UIViewControllerRepresentable {
    
    @Binding var isShown: Bool // Controls the visibility of the camera view
    
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
}

