//
//  CameraView.swift
//  Recamgnition
//
//  Created by Tykhon on 16.06.2026.
//

import SwiftUI
import SwiftData

struct CameraView: View {
    
    enum Tab: Hashable {
        case cameraTab
        case historyTab
    }
    
    @Environment(\.scenePhase) private var scenePhase
    @State private var selectedTab: Tab = .cameraTab
    
    let cameraViewModel: CameraViewModel

    
    var body: some View {
        
        ZStack {
            switch cameraViewModel.cameraState {
                
            case .running, .altTabbed:
                TabView(selection: $selectedTab) {
                    ZStack {
                        CameraPreviewBridge(session: cameraViewModel.captureSession)
                            .ignoresSafeArea()
                        
                        switch cameraViewModel.captureMode {
                            
                        case .recognition:
                            RecognitionView(currentRecognition: cameraViewModel.currentRecognition)
                            
                        case .codes:
                            ScannerView(scannedResult: cameraViewModel.scannedResult, onReset: cameraViewModel.resumeScanning)
                            
                        }
                        
                        VStack {
                            topBar
                            Spacer()
                        }
                    }
                    .tabItem {
                        Label("", systemImage: "camera.fill")
                    }
                    .tag(Tab.cameraTab)
                    .onAppear {
                        cameraViewModel.start()
                    }
                    
                    HistoryView()
                        .tabItem {
                            Label("", systemImage: "list.bullet.rectangle.portrait")
                        }
                        .tag(Tab.historyTab)
                        .onAppear {
                            cameraViewModel.stopAltTab()
                        }
                }
                
                
            case .idle, .requestingPermission, .configuring:
                ProgressView()
                
            case .permissionDenied, .restricted:
                VStack {
                    ContentUnavailableView(
                        "Camera Access Required",
                        systemImage: "camera.fill",
                        description: Text("Please, allow camera access in settings.")
                    )
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(.primary)
                    
                    Button() {
                        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
                        UIApplication.shared.open(url)
                    } label: {
                        Label("Open settings", systemImage: "arrow.forward")
                    }
                    .font(.callout)
                    .fontWeight(.bold)
                    
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
                ContentUnavailableView("Camera is on hold", systemImage: "zzz")
                
//                VStack (spacing: 16) {
//                    Image(systemName: "zzz")
//                        .resizable()
//                        .aspectRatio(contentMode: .fit)
//                        .frame(maxWidth: 120, maxHeight: 120)
//                    
//                    Text("Camera is on hold")
//                        .font(.title2)
//                        .fontWeight(.bold)
//                        .foregroundStyle(.primary)
//                }
                
                
            default:
                Text("UNKNOWN STATE")
                    .font(.title2)
                    .fontWeight(.bold)
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
    
    private var topBarName: String {
        switch cameraViewModel.captureMode {
        case .codes: String(localized: "top_bar_name.codes", defaultValue: "Code Scanner")
        case .recognition: String(localized: "top_bar_name.recognition", defaultValue: "Object classification")
        }
    }
    
    private var topBarDescription: String {
        switch cameraViewModel.captureMode {
        case .codes: String(localized: "top_bar_description.codes", defaultValue: "Point the camera at the code")
        case .recognition: String(localized: "top_bar_description.recognition", defaultValue: "Point the camera at the object")
        }
    }
    
    @ViewBuilder
    private var topBar: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(topBarName)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                    .shadow(radius: 2)
                Text(topBarDescription)
                    .font(.footnote)
                    .foregroundStyle(.white.opacity(0.5))
                    .shadow(radius: 1)
            }
            
            Spacer()
            HStack(spacing: 4) {
                Button {
                    withAnimation(.spring(duration: 0.3)) {
                        cameraViewModel.toggleTorch()
                    }
                } label: {
                    Image(systemName: torchIconName)
                        .frame(maxWidth: 50, maxHeight: 50)
                        .background(.ultraThinMaterial, in: Circle())
                        .overlay(Circle().stroke(Color.white.opacity(0.3), lineWidth: 0.5))
                        .foregroundStyle(cameraViewModel.isTorchOn ? .yellow : .primary)
                }
                
                switch cameraViewModel.captureMode {
                    
                case .codes:
                    Button {
                        withAnimation(.spring(duration: 0.3)) {
                            cameraViewModel.switchCaptureMode(to: .recognition)
                        }
                    } label: {
                        Image(systemName: cameraViewModel.captureMode.iconName)
                            .frame(maxWidth: 50, maxHeight: 50)
                            .background(.ultraThinMaterial, in: Circle())
                            .overlay(Circle().stroke(Color.white.opacity(0.3), lineWidth: 0.5))
                            .foregroundStyle(.black)
                            .contentTransition(.symbolEffect(.replace))
                    }
                    
                case .recognition:
                    Button {
                        withAnimation(.spring(duration: 0.3)) {
                            cameraViewModel.switchCaptureMode(to: .codes)
                        }
                    } label: {
                        Image(systemName: cameraViewModel.captureMode.iconName)
                            .frame(maxWidth: 50, maxHeight: 50)
                            .background(.ultraThinMaterial, in: Circle())
                            .overlay(Circle().stroke(Color.white.opacity(0.3), lineWidth: 0.5))
                            .foregroundStyle(.black)
                            .contentTransition(.symbolEffect(.replace))
                    }
                }
            }
        }
        .padding()
    }
}


//#Preview ("English") {
//    ZStack {
//        CameraView(cameraViewModel: )
//    }
//    .environment(\.locale, Locale(identifier: "EN"))
//}
//
//#Preview ("Russian") {
//    ZStack {
//        CameraView(cameraViewModel: )
//    }
//    .environment(\.locale, Locale(identifier: "RU"))
//}
