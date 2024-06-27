import SwiftUI
import AVFoundation

struct ContentView: View {
    @StateObject private var viewModel = ViewModel()

    var body: some View {
        ZStack(alignment: .topLeading) {
            CameraView()
                .edgesIgnoringSafeArea(.all)
                .environmentObject(viewModel)
            
            VStack(alignment: .leading, spacing: 5) {
                Text("Splits")
                    .font(.system(size: 18))
                    .foregroundColor(.white)
                    .padding([.leading, .top], 10)
                    .background(Color.black.opacity(1))
                    .cornerRadius(6)
                
                List(viewModel.splits, id: \.id) { split in
                    HStack {
                        Text("\(split.timeString) | \(split.totalElapsedTimeString)")
                            .font(.system(size: 12))
                            .foregroundColor(.white)
                            .padding(1)
                            .background(Color.black.opacity(0.7))
                            .cornerRadius(5)
                    }
                    .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                }
                .listStyle(PlainListStyle())
                .frame(width: 120, alignment: .leading)
                
                Spacer()
            }
            
            VStack {
                Spacer()
                HStack {
                    Button(action: {
                        viewModel.toggleCamera()
                    }) {
                        Image(systemName: "camera.rotate")
                            .font(.title)
                            .foregroundColor(.white)
                            .frame(width: 60, height: 60)
                            .background(Color.gray.opacity(0.7))
                            .clipShape(Circle())
                            .overlay(
                                Circle()
                                    .stroke(Color.white, lineWidth: 2)
                            )
                    }
                    .padding(.bottom, 50)
                    .padding(.leading, 30)
                    
                    Spacer()
                    
                    Button(action: {
                        if viewModel.isRecording {
                            viewModel.stopRecording()
                        } else {
                            viewModel.startRecording()
                        }
                    }) {
                        Text(viewModel.isRecording ? "Stop" : "Start")
                            .font(.title)
                            .foregroundColor(.white)
                            .frame(width: 80, height: 80)
                            .background(viewModel.isRecording ? Color.red : Color.green)
                            .clipShape(Circle())
                            .overlay(
                                Circle()
                                    .stroke(Color.white, lineWidth: 2)
                            )
                    }
                    .padding(.bottom, 50)
                    
                    Spacer()
                }
            }
        }
        .onAppear {
            viewModel.setupOrientationObserver()
        }
        .onDisappear {
            viewModel.removeOrientationObserver()
        }
    }
}

