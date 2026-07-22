//
//  CameraService.swift
//  Recamgnition
//
//  Created by Tykhon on 20.07.2026.
//

import AVFoundation

protocol CameraServiceProtocol: AnyObject {
    var captureSession: AVCaptureSession { get }
    var delegate: CameraServiceDelegate? { get set }
    var cameraState: CameraState { get }
    
    func startSession()
    func stopSession()
    func setUpCaptureSession() async
}

protocol CameraServiceDelegate: AnyObject {
    func cameraService(
        _ service: any CameraServiceProtocol,
        didOutput sampleBuffer: CMSampleBuffer
    )
}


final class CameraService: NSObject, CameraServiceProtocol {
    
    weak var delegate: CameraServiceDelegate?
    
    private let sessionQueue = DispatchQueue(label: "sessionQueue")
    
    private(set) var cameraState: CameraState = .idle
    
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
        cameraState = .requestingPermission
        guard await isAuthorized else {
            cameraState = .permissionDenied
            return
        }
        
        cameraState = .configuring
        
        do {
            try configureSession()
        } catch let error as CameraSetupError {
            cameraState = .failed(error)
        } catch {
            cameraState = .failed(.unknown("DEBUG: Unknown error \(error.localizedDescription)"))
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
        cameraState = .running
        
        guard !self.captureSession.isRunning else { return }
        
        self.captureSession.startRunning()
    }
    
    func stopSession() {
        cameraState = .idle
        
        guard self.captureSession.isRunning else { return }
        
        self.captureSession.stopRunning()
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
    case permissionDenied
    case failed(CameraSetupError)
}

enum CameraSetupError: Error, Equatable {
    case deviceUnaviable
    case cannotCreateInput
    case cannotAddInput
    case cannotAddOutput
    case unknown(String)
}
