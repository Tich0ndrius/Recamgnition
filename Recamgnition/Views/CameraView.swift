//
//  CameraView.swift
//  Recamgnition
//
//  Created by Tykhon on 16.06.2026.
//

import SwiftUI

struct CameraView: View {
    @Environment(\.scenePhase) private var scenePhase
    @State var cameraViewModel = CameraViewModel(
        cameraService: CameraService(),
        recognitionService: RecognitionService()
    )
    
    var body: some View {
        ZStack {
            switch cameraViewModel.cameraState {
            
            case .running:
                CameraPreviewBridge(session: cameraViewModel.captureSession)
                    .ignoresSafeArea()
                    
                
                VStack {
                    Spacer()
                    
                    if let recognition = cameraViewModel.currentRecognition {
                        Text(
                            "\(recognition.identifier.capitalized)" +
                            ", " +
                            "\(Int(recognition.confidence * 100))%"
                        )
                            .font(.title)
                            .padding()
                            .background(RoundedRectangle(cornerRadius: 10).fill(Color.cyan.opacity(0.5)))
                            .padding(.bottom)
                    } else {
                        Text("Point the camera to the object...")
                            .font(.title)
                            .padding()
                            .background(RoundedRectangle(cornerRadius: 10).fill(Color.cyan.opacity(0.5)))
                            .padding(.bottom)
                    }
                }
                
            case .idle, .requestingPermission, .configuring:
                ProgressView()
                
            case .permissionDenied, .restricted:
                ContentUnavailableView(
                    "Camera Access Required",
                    systemImage: "camera.fill",
                    description: Text("Please, allow camera access in Settings.")
                )
                    Button("Open settings") {
                        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
                        UIApplication.shared.open(url)
                    }
                
                
            case .failed(let error):
                ContentUnavailableView(
                    "Camera Error",
                    systemImage: "exclamationmark.fill",
                    description: Text(error.localizedDescription)
                )
                Button("Retry") {
                    Task {
                        await cameraViewModel.setUpCameraAndStart()
                    }
                }
            
            case .ready:
                Text("Camera is on hold.")
                
            default:
                Text("UNKNOWN STATE")
            }
            
            
        }
        .task {
            await cameraViewModel.setUpCameraAndStart()
        }
        .onChange(of: scenePhase) { _, newPhase in
            
            switch newPhase {
            case .active: cameraViewModel.start()
                
            case .inactive, .background: cameraViewModel.stop()
                
            @unknown default: break
            }
        }
    }
}

#Preview ("English") {
    ZStack {
        CameraView()
    }
}

#Preview ("Russian") {
    ZStack {
        CameraView()
    }
    .environment(\.locale, Locale(identifier: "RU"))
}
