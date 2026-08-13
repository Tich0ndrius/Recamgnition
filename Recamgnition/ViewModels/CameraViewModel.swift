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
    private let scanHistoryRepository: any ScanHistoryRepositoryProtocol
    
    private var stateObservationTask: Task<Void, Never>?
    private var recognitionObservationTask: Task<Void, Never>?
    private var scannedResultObservationTask: Task<Void, Never>?
    
    private(set) var cameraState: CameraState = .idle
    private(set) var captureMode: CaptureMode = .recognition
    private(set) var isTorchOn: Bool = false
    private(set) var scannedResult: ScannedResult?
    private(set) var currentRecognition: RecognitionResult?
    
    let captureSession: AVCaptureSession

    
    init(
        cameraService: any CameraServiceProtocol,
        recognitionService: any RecognitionServiceProtocol,
        scanHistoryRepository: any ScanHistoryRepositoryProtocol
    ) {
        self.cameraService = cameraService
        self.recognitionService = recognitionService
        self.scanHistoryRepository = scanHistoryRepository
        
        captureSession = cameraService.captureSession
        
        startObservingCameraStates()
        startObservingRecognitionResults()
        startObservingScannedResults()
        recognitionService.startObservingFramesAndProcess(sampleBufferStream: cameraService.sampleBufferStream)
    }
    
    // MARK: -
    
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
    
    func startObservingScannedResults() {
        guard scannedResultObservationTask == nil else { return }
        
        let results = cameraService.scannedResultStream
        
        scannedResultObservationTask = Task { [weak self] in
            for await newResult in results {
                guard let self = self else { break }
                
                self.handleScanResult(newResult)
//                self.scannedResult = newResult
            }
        }
    }
    
    func startObservingRecognitionResults() {
        guard recognitionObservationTask == nil else { return }
        
        let results = recognitionService.recognitionResultStream
        
        recognitionObservationTask = Task { [weak self] in
            for await newResult in results {
                guard let self = self else { break }
                
                self.currentRecognition = newResult
            }
        }
    }
    
    private func handleScanResult(_ result: ScannedResult) {
        self.scannedResult = result
        scanHistoryRepository.add(result)
        
    }
    
    
    func switchCaptureMode(to newMode: CaptureMode) {
        cameraService.switchCaptureMode(to: newMode)
        captureMode = newMode
    }
    
    func toggleTorch() {
        do {
            isTorchOn = try cameraService.toggleTorch(!isTorchOn)
        } catch {
            print("\(error.localizedDescription)")
        }
    }
    
    func resumeScanning() {
        cameraService.resumeScanning()
        scannedResult = nil
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
    
    func stopAltTab() {
        cameraService.stopSessionAltTab()
    }
}


#if DEBUG

extension CameraViewModel {
    static func mock(
        cameraState: CameraState = .running,
        recognitionResult: RecognitionResult? = nil,
        mockHistory: [ScanHistoryEntity] = []
        ) -> Self {
       
        let mockCameraService = CameraServiceMock(initialState: cameraState)
        let fakeRecognitionService = RecognitionService()
        let mockScanHistoryRepo = ScanHistoryRepositoryMock()
        
        return Self(
            cameraService: mockCameraService,
            recognitionService: fakeRecognitionService,
            scanHistoryRepository: mockScanHistoryRepo
        )
    }
}

#endif
