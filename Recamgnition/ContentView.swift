//
//  ContentView.swift
//  Recamgnition
//
//  Created by Tykhon on 16.06.2026.
//

import SwiftUI

struct ContentView: View {
    @State var cameraViewModel = CameraViewModel()
    
    var body: some View {
        ZStack {
            CameraPreview(session: cameraViewModel.captureSession)
                .ignoresSafeArea()
                .task {
                    await cameraViewModel.setUpCaptureSession()
                }
            
            VStack {
                Spacer()
                
                Text(cameraViewModel.currentObject.capitalized + ", " + "\(Int(cameraViewModel.confidence * 100))%")
                    .font(.title)
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 10).fill(Color.cyan.opacity(0.5)))
                    .padding(.bottom)
            }
        }
    }
}

#Preview {
    ContentView()
}
