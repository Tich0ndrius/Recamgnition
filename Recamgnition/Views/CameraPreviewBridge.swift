//
//  CameraPreviewBridge.swift
//  Recamgnition
//
//  Created by Tykhon on 17.06.2026.
//

import SwiftUI
import AVFoundation

struct CameraPreviewBridge: UIViewRepresentable {
    let session: AVCaptureSession
    
    func makeUIView(context: Context) -> PreviewViewLayer {
        
        let view = PreviewViewLayer()
        
        view.videoPreviewLayer.session = session
        view.videoPreviewLayer.videoGravity = .resizeAspectFill
        
        return view
    }
    
    func updateUIView(
        _ uiView: PreviewViewLayer,
        context: Context
    ) {}
}
