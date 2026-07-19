//
//  CameraViewModel.swift
//  Recamgnition
//
//  Created by Tykhon on 16.06.2026.
//

import Observation
import AVFoundation
import Vision

@Observable final class CameraViewModel: NSObject {
    private let sessionQueue = DispatchQueue(label: "sessionQueue")
    let captureSession = AVCaptureSession()
    var currentObject = ""
    var confidence: Float = 0.0
    private var state: CameraState = .idle
    private var isProcessing = false
    
    // MARK: Authorization
    var isAuthorized: Bool {
        get async {
            let status = AVCaptureDevice.authorizationStatus(for: .video)
            var isAuthorized = status == .authorized
            
            if status == .notDetermined {
                isAuthorized = await AVCaptureDevice.requestAccess(for: .video)
            }
            return isAuthorized
        }
    }
    
    // MARK: Capture Session Set-up
    func setUpCaptureSession() async {
        state = .requestingPermission
        guard await isAuthorized else {
            state = .denied
            return
        }

        state = .configuring
        
        do {
            try configureSession()
            startSession()
            state = .running
            
        } catch let error as CameraSetupError {
            state = .failed(error)
        } catch {
            state = .failed(.unknown("DEBUG: Unknown error \(error.localizedDescription)"))
        }
    }
    
    private func configureSession() throws {
        captureSession.beginConfiguration()
        defer { captureSession.commitConfiguration() }
        
        let videoOutput = AVCaptureVideoDataOutput()
        
        guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
            throw CameraSetupError.deviceUnaviable
        }
        
        guard let videoDeviceInput = try? AVCaptureDeviceInput(device: videoDevice) else {
            throw CameraSetupError.cannotCreateInput
        }
        
        guard captureSession.canAddInput(videoDeviceInput) else {
            throw CameraSetupError.cannotAddInput
        }
        captureSession.addInput(videoDeviceInput)
        
        videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "sampleBufferQueue"))
        
        guard captureSession.canAddOutput(videoOutput) else {
            throw CameraSetupError.cannotAddOutput
        }
        
        captureSession.addOutput(videoOutput)
        
        if let connection = videoOutput.connection(with: .video) {
            let targetAngle: CGFloat = TargetAngle.portrait.rawValue
            if connection.isVideoRotationAngleSupported(targetAngle) {
                connection.videoRotationAngle = targetAngle
            }
        }
    }
    
    func startSession() {
        sessionQueue.async { [weak self] in
            guard let self else { return }
            
            if !self.captureSession.isRunning {
                self.captureSession.startRunning()
            }
        }
    }
    
    func stopSession() {
        sessionQueue.async { [weak self] in
            guard let self else { return }
            
            if self.captureSession.isRunning {
                self.captureSession.stopRunning()
            }
        }
    }
}


extension CameraViewModel: AVCaptureVideoDataOutputSampleBufferDelegate {
    // MARK: Converting raw data to Pixel Buffer without copying
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
        guard let pixelBuffer: CVPixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        processFrame(pixelBuffer)
    }
    
    // MARK: Vision implementation
    private func processFrame(_ pixelBuffer: CVPixelBuffer) {
        guard !isProcessing else { return }
        isProcessing = true
        defer { isProcessing = false }
        
        let request = VNClassifyImageRequest()
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer)
        
        try? handler.perform([request])
        
        guard let observation = request.results?.first as? VNClassificationObservation else { return }
        
        if currentObject != observation.identifier {
            if observation.confidence > 0.7{
                DispatchQueue.main.async {
                    self.currentObject = observation.identifier
                    self.confidence = observation.confidence
                }
            }
        }
    }
}

enum TargetAngle: CGFloat {
    case landscapeRight = 0.0
    case portrait = 90.0
    case landscapeLeft = 180.0
    case upsideDownPortrait = 270.0
}

enum CameraState: Equatable {
    case idle
    case requestingPermission
    case configuring
    case running
    case denied
    case failed(CameraSetupError)
}

enum CameraSetupError: Error, Equatable {
    case permissionDenied
    case deviceUnaviable
    case cannotCreateInput
    case cannotAddInput
    case cannotAddOutput
    case unknown(String)
}
