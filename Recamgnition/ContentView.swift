//
//  ContentView.swift
//  Recamgnition
//
//  Created by Tykhon on 16.06.2026.
//

import SwiftUI

struct ContentView: View {
    @Environment(\.scenePhase) private var scenePhase
    @State var cameraViewModel = CameraViewModel()
    
    var body: some View {
        ZStack {
            CameraPreview(session: cameraViewModel.captureSession)
                .ignoresSafeArea()
                .task {
                    await cameraViewModel.setUpCaptureSession()
                    cameraViewModel.startSession()
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
            case .active: cameraViewModel.startSession()
                
            case .inactive, .background: cameraViewModel.stopSession()
                
            @unknown default: break
            }
        }
    }
}

#Preview {
    ContentView()
}
