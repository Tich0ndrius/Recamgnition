//
//  CameraViewModel.swift
//  Recamgnition
//
//  Created by Tykhon on 16.06.2026.
//

import Observation
import AVFoundation

@MainActor
@Observable
final class CameraViewModel {
    private var lastProcessingTime: CFTimeInterval = 0
    private let processingInterval: CFTimeInterval = 0.1
    
    private let recognitionService = RecognitionService()
    private let cameraService = CameraService()
    
    var currentRecognition: RecognitionResult?
    
    let captureSession: AVCaptureSession

    
    init() {
        captureSession = cameraService.captureSession
        cameraService.delegate = self
    }
    
    func setupCamera() async {
        await cameraService.setUpCaptureSession()
    }
    
    func start() {
        cameraService.startSession()
    }
    
    func stop() {
        cameraService.stopSession()
    }
}

extension CameraViewModel: CameraServiceDelegate {
    func cameraService(
        _ service: CameraService,
        didOutput sampleBuffer: CMSampleBuffer
    ) {
        //Limiting FPS for processing
        let currentTime = CACurrentMediaTime()
        guard currentTime - lastProcessingTime >= processingInterval else { return }
        lastProcessingTime = currentTime
        
        guard let result = recognitionService.processFrame(sampleBuffer) else { return }
        
        guard result != currentRecognition else { return }
        
        Task { @MainActor in
            currentRecognition = result
        }
    }
}
