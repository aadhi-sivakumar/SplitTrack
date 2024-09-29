import SwiftUI
import AVFoundation

struct ContentView: View {
    
    @State private var showingCamera = false // Controls camera visibility
    @State private var cameraAccessDenied = false // Controls alert if access is denied
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Welcome to SplitTrack!")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding()
            
            Text("SplitTrack allows you to take photos or record videos with ease. Just click the button below to get started.")
                .multilineTextAlignment(.center)
                .padding()
            
            Button(action: requestCameraAccess) {
                Text("Open Camera")
                    .font(.title2)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(10)
            }
            .padding()
            .alert(isPresented: $cameraAccessDenied) {
                Alert(title: Text("Camera Access Denied"),
                      message: Text("Please enable camera access in settings to use this feature."),
                      dismissButton: .default(Text("OK")))
            }
            
            Spacer()
        }
        .sheet(isPresented: $showingCamera) {
            CameraView(isShown: self.$showingCamera) // Camera view as a sheet
        }
    }
    
    // Request camera access and open the camera if allowed
    func requestCameraAccess() {
        AVCaptureDevice.requestAccess(for: .video) { granted in
            if granted {
                self.showingCamera = true
            } else {
                self.cameraAccessDenied = true
            }
        }
    }
}

