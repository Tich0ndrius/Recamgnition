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
                NavigationStack {
                    ZStack {
                        CameraPreviewBridge(session: cameraViewModel.captureSession)
                            .ignoresSafeArea()
                        
                        
                        switch cameraViewModel.captureMode {
                            
                        case .recognition:
                            RecognitionView(currentRecognition: cameraViewModel.currentRecognition)
                            
                        case .codes:
                            ScannerView(scannedResult: cameraViewModel.scannedResult, onReset: cameraViewModel.resetScannedResult)
                            
                        }
                    }
                    .toolbar {
                        ToolbarItem(placement: .primaryAction) {
                            Button {
                                withAnimation(.spring(duration: 0.3)) {
                                    cameraViewModel.toggleTorch()
                                }
                            } label: {
                                Image(systemName: torchIconName)
                                    .foregroundStyle(cameraViewModel.isTorchOn ? .yellow : .primary)
                            }
                        }
                        
                        ToolbarSpacer(placement: .primaryAction)
                        
                        switch cameraViewModel.captureMode {
                        case .codes:
                            ToolbarItem(placement: .primaryAction) {
                                Button {
                                    withAnimation(.spring(duration: 0.3)) {
                                        cameraViewModel.switchCaptureMode(to: .recognition)
                                    }
                                } label: {
                                    Image(systemName: cameraViewModel.captureMode.iconName)
                                        .contentTransition(.symbolEffect(.replace))
                                }
                            }
                        case .recognition:
                            ToolbarItem(placement: .primaryAction) {
                                Button {
                                    withAnimation(.spring(duration: 0.3)) {
                                        cameraViewModel.switchCaptureMode(to: .codes)
                                    }
                                } label: {
                                    Image(systemName: cameraViewModel.captureMode.iconName)
                                        .contentTransition(.symbolEffect(.replace))
                                }
                            }
                        }
                    }
                }
                
            case .idle, .requestingPermission, .configuring:
                ProgressView()
                
            case .permissionDenied, .restricted:
                VStack {
                    ContentUnavailableView(
                        "Camera Access Required",
                        systemImage: "camera.fill",
                        description: Text("Please, allow camera access in Settings.")
                    )
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(.primary)
                    
                    Button() {
                        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
                        UIApplication.shared.open(url)
                    } label: {
                        Label("Open settings", systemImage: "arrow.forward")
                    }
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.primary)
                    
                    Spacer()
                }
                .padding()
                
                
            case .failed(let error):
                VStack {
                    ContentUnavailableView(
                        "Camera Error",
                        systemImage: "exclamationmark.fill",
                        description: Text(error.localizedDescription)
                    )
                    Button() {
                        Task {
                            await cameraViewModel.setUpCameraAndStart()
                        }
                    } label: {
                        Label("Retry", systemImage: "arrow.clockwise")
                    }
                    
                    Spacer()
                }
                .padding()
                
            case .ready:
                Text("Camera is on hold")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(.primary)
                
            default:
                Text("UNKNOWN STATE")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(.primary)
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

extension CameraView {
    private var torchIconName: String {
        cameraViewModel.isTorchOn ? "bolt.fill" : "bolt.slash.fill"
    }
}

#Preview ("English") {
    ZStack {
        CameraView()
    }
    .environment(\.locale, Locale(identifier: "EN"))
}

#Preview ("Russian") {
    ZStack {
        CameraView()
    }
    .environment(\.locale, Locale(identifier: "RU"))
}
