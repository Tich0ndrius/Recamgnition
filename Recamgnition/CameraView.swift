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
            CameraPreviewBridge(session: cameraViewModel.captureSession)
                .ignoresSafeArea()
                .task {
                    await cameraViewModel.setupCamera()
                    cameraViewModel.start()
                }
            
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
                }
            }
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

#Preview {
    CameraView()
}
