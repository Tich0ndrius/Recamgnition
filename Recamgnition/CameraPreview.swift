//
//  CameraPreview.swift
//  Recamgnition
//
//  Created by Tykhon on 17.06.2026.
//

import SwiftUI
import AVFoundation

struct CameraPreview: UIViewRepresentable {
    let session: AVCaptureSession
    
    func makeUIView(context: Context) -> PreviewView {
        
        let view = PreviewView()
        
        view.videoPreviewLayer.session = session
        view.videoPreviewLayer.videoGravity = .resizeAspectFill
        
        return view
    }
    
    func updateUIView(
        _ uiView: PreviewView,
        context: Context
    ) {}
}
