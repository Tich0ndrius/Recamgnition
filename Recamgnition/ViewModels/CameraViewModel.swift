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
    
    private let cameraService: any CameraServiceProtocol
    private let recognitionService: any RecognitionServiceProtocol
    private var stateObservationTask: Task<Void, Never>?
    
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
        startObservingCameraStates()
    }
    
    func startObservingCameraStates() {
        guard stateObservationTask == nil else { return }
        
        let states = cameraService.cameraStateStream
        
        stateObservationTask = Task { [weak self] in
            for await newState in states {
                guard let self = self else { break }
                self.cameraState = newState
            }
        }
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
    
    func cameraService(_ service: any CameraServiceProtocol, didOutput sampleBuffer: CMSampleBuffer) {
        guard let result = recognitionService.processFrame(sampleBuffer) else { return }
        
        guard result != currentRecognition else { return }
        
        Task { @MainActor in
            currentRecognition = result
        }
    }
}
