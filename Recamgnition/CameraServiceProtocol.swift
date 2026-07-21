//
//  CameraServiceProtocol.swift
//  Recamgnition
//
//  Created by Tykhon on 21.07.2026.
//

import AVFoundation

protocol CameraServiceProtocol: AnyObject {
    var captureSession: AVCaptureSession { get }
    var delegate: CameraServiceDelegate? { get set }
    
    func startSession()
    func stopSession()
    func setUpCaptureSession() async
}
