import SwiftUI
import AVFoundation

struct ContentView: View {
    
    @State private var showingCamera = false // Controls camera visibility
    @State private var cameraAccessDenied = false // Controls alert if access is denied
    @State private var textWidth: CGFloat = 0 // Variable to store text width
    
    var body: some View {
        ZStack {
            Color(red: 231/255, green: 71/255, blue: 78/255) // Background color in RGB
                .ignoresSafeArea() // Ensure the background covers the whole screen
            
            VStack(spacing: 20) {
                // Add the image above the text, width matches text width
                Image("SplitTrack App logo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: textWidth, height: textWidth * 0.75) // Keeping the aspect ratio (4:3)
                    .padding(.bottom, 10)
                
                // Measure the width of the "Welcome to SplitTrack!" text
                Text("Welcome to SplitTrack!")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding()
                    .background(GeometryReader { geometry in
                        Color.clear.onAppear {
                            // Capture the width of the text
                            self.textWidth = geometry.size.width
                        }
                    })
                
                Text("SplitTrack allows you to take photos or record videos with ease. Just click the button below to get started.")
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                Button(action: requestCameraAccess) {
                    Text("Open Camera")
                        .font(.title2)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(10)
                }
                .alert(isPresented: $cameraAccessDenied) {
                    Alert(title: Text("Camera Access Denied"),
                          message: Text("Please enable camera access in settings to use this feature."),
                          dismissButton: .default(Text("OK")))
                }
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity) // Make the VStack fill the available space
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

