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
    
    private let cameraService: any CameraServiceProtocol
    private let recognitionService: any RecognitionServiceProtocol
    
    var cameraState: CameraState = .idle
    var currentRecognition: RecognitionResult?
    let captureSession: AVCaptureSession

    
    init(
        cameraService: any CameraServiceProtocol,
        recognitionService: any RecognitionServiceProtocol
    ) {
        self.cameraService = cameraService
        self.recognitionService = recognitionService
        
        captureSession = cameraService.captureSession
        cameraService.delegate = self
    }
    
    func setupCamera() async {
//        guard captureSession.inputs.isEmpty else { return }
        await cameraService.setUpCaptureSession()
    }
    
    func start() {
        cameraService.startSession()
        
        cameraState = cameraService.cameraState
    }
    
    func stop() {
        cameraService.stopSession()
        
        cameraState = cameraService.cameraState
    }
}

extension CameraViewModel: CameraServiceDelegate {
    func cameraService(
        _ service: any CameraServiceProtocol,
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
