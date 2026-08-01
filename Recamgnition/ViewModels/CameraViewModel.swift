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
    private var recognitionObservationTask: Task<Void, Never>?
    
    var cameraState: CameraState = .idle
    var captureMode: CaptureMode = .recognition
    var currentRecognition: RecognitionResult?
    let captureSession: AVCaptureSession
    

    
    init(
        cameraService: any CameraServiceProtocol,
        recognitionService: any RecognitionServiceProtocol
    ) {
        self.cameraService = cameraService
        self.recognitionService = recognitionService
        
        captureSession = cameraService.captureSession
        
        startObservingCameraStates()
        startObservingRecognitionResults()
        recognitionService.startObservingFramesAndProcess(sampleBufferStream: cameraService.sampleBufferStream)
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
    
    func startObservingRecognitionResults() {
        guard recognitionObservationTask == nil else { return }
        
        let results = recognitionService.resultStream
        
        recognitionObservationTask = Task { [weak self] in
            for await newResult in results {
                guard let self = self else { break }
                self.currentRecognition = newResult
            }
        }
        
        
    }
    
    func toggleCaptureMode() {
        cameraService.toggleCaptureMode()
        captureMode = cameraService.currentMode
    }
    
    func setUpCameraAndStart() async {
        await cameraService.setUpCaptureSession()
        start()
    }
    
    func start() {
        cameraService.startSession()
    }
    
    func stop() {
        cameraService.stopSession()
    }
}
