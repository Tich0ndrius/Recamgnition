//
//  PreviewViewLayer.swift
//  Recamgnition
//
//  Created by Tykhon on 17.06.2026.
//

import UIKit
import AVFoundation

final class PreviewViewLayer: UIView {
    override class var layerClass: AnyClass {
        AVCaptureVideoPreviewLayer.self
    }
    
    var videoPreviewLayer: AVCaptureVideoPreviewLayer {
        layer as! AVCaptureVideoPreviewLayer
    }
}
