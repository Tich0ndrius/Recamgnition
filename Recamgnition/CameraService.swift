//
//  CameraService.swift
//  Recamgnition
//
//  Created by Tykhon on 20.07.2026.
//

import AVFoundation

protocol CameraServiceDelegate: AnyObject {
    func cameraService(
        _ service: CameraService,
        didOutput sampleBuffer: CMSampleBuffer
    )
}


final class CameraService: NSObject {
    
    weak var delegate: CameraServiceDelegate?
    
    private let sessionQueue = DispatchQueue(label: "sessionQueue")

    private var state: CameraState = .idle
    
    let captureSession = AVCaptureSession()
    
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
        videoOutput.alwaysDiscardsLateVideoFrames = true
        
        guard let videoDevice = AVCaptureDevice.default(
            .builtInWideAngleCamera,
            for: .video,
            position: .back
        ) else {
            throw CameraSetupError.deviceUnaviable
        }
        
        guard let videoDeviceInput = try? AVCaptureDeviceInput(device: videoDevice) else {
            throw CameraSetupError.cannotCreateInput
        }
        
        guard captureSession.canAddInput(videoDeviceInput) else {
            throw CameraSetupError.cannotAddInput
        }
        captureSession.addInput(videoDeviceInput)
        
        videoOutput.setSampleBufferDelegate(
            self,
            queue: DispatchQueue(label: "sampleBufferQueue")
        )
        
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
    
    
    // MARK: Camera Life Cycle
    func startSession() {
        sessionQueue.async {
            
            guard !self.captureSession.isRunning else { return }
            
            self.captureSession.startRunning()
            Task { @MainActor in
                self.state = .running
            }
        }
    }
    
    func stopSession() {
        sessionQueue.async {
            
            guard self.captureSession.isRunning else { return }
            
            self.captureSession.stopRunning()
            
            Task { @MainActor in
                self.state = .idle
            }
        }
    }
}



extension CameraService: AVCaptureVideoDataOutputSampleBufferDelegate {
    // MARK: Converting raw data to Pixel Buffer without copying
    func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        delegate?.cameraService(
            self,
            didOutput: sampleBuffer
        )
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
