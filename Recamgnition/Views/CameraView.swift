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
        NavigationStack {
            ZStack {
                switch cameraViewModel.cameraState {
                
                case .running:
                    CameraPreviewBridge(session: cameraViewModel.captureSession)
                        .ignoresSafeArea()
                        
                    switch cameraViewModel.captureMode {
                    case .recognition:
                        RecognitionView()
                        
                    case .codes:
                        ScannerView()
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
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        withAnimation(.spring(duration: 0.3)) {
                            cameraViewModel.toggleCaptureMode()
                        }
                    } label: {
                        Image(systemName: cameraViewModel.captureMode.iconName)
                            .contentTransition(.symbolEffect(.replace))
                    }
                }
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
