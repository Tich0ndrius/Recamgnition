//
//  CameraService.swift
//  Recamgnition
//
//  Created by Tykhon on 20.07.2026.
//

import AVFoundation

protocol CameraServiceProtocol: AnyObject {
    var captureSession: AVCaptureSession { get }
    var cameraStateStream: AsyncStream<CameraState> { get }
    var sampleBufferStream: AsyncStream<CMSampleBuffer> { get }
    
    func startSession()
    func stopSession()
    func setUpCaptureSession() async
}

final class CameraService: NSObject, CameraServiceProtocol {
    
    private let sessionQueue = DispatchQueue(label: "sessionQueue")
    
    let cameraStateStream: AsyncStream<CameraState>
    private let stateContinuation: AsyncStream<CameraState>.Continuation
    private(set) var currentState: CameraState = .idle
    
    let sampleBufferStream: AsyncStream<CMSampleBuffer>
    private let frameContinuation: AsyncStream<CMSampleBuffer>.Continuation
    
    let captureSession = AVCaptureSession()
    private(set) var isAuthorized: Bool = false
    
    
    override init() {
        let (stateStream, stateContinuation) = AsyncStream.makeStream(
            of: CameraState.self,
            bufferingPolicy: .bufferingNewest(1)
        )
        self.cameraStateStream = stateStream
        self.stateContinuation = stateContinuation
        
        let (frameStream, frameContinuation) = AsyncStream.makeStream(
            of: CMSampleBuffer.self,
            bufferingPolicy: .bufferingNewest(1)
        )
        self.sampleBufferStream = frameStream
        self.frameContinuation = frameContinuation
        
        super .init()
        self.stateContinuation.yield(.idle)
    }
    
    deinit {
        stateContinuation.finish()
        frameContinuation.finish()
    }
    
    
    // MARK: Authorization
    func checkForAuthorization() async {
        transition(to: .requestingPermission)
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        
        switch status {
        case .authorized:
            isAuthorized = true
            transition(to: .permissionGranted)
            
        case .restricted:
            transition(to: .restricted)
            
        case .denied:
            transition(to: .permissionDenied)
        
        case .notDetermined:
            transition(to: .requestingPermission)
            isAuthorized = await AVCaptureDevice.requestAccess(for: .video)
        
            
        @unknown default:
            break
        }
    }
    
    func transition(to newState: CameraState) {
        guard newState != currentState else { return }
        
        currentState = newState
        stateContinuation.yield(newState)
    }
    
    // MARK: Capture Session Set-up
    func setUpCaptureSession() async {
        await checkForAuthorization()
        guard isAuthorized else { return }

        transition(to: .configuring)
        
        do {
            try configureSession()
            transition(to: .ready)
        } catch let error as CameraSetupError {
            transition(to: .failed(error))
        } catch {
            transition(to: .failed(.unknown("DEBUG: Unknown error \(error.localizedDescription)")))
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
        transition(to: .running)
        
        sessionQueue.async {
            guard !self.captureSession.isRunning else { return }
            
            self.captureSession.startRunning()
        }
    }
    
    func stopSession() {
        transition(to: .ready)
        
        sessionQueue.async {
            guard self.captureSession.isRunning else { return }
            
            self.captureSession.stopRunning()
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
        frameContinuation.yield(sampleBuffer)
    }
}


enum TargetAngle: CGFloat {
    case landscapeRight = 0.0
    case portrait = 90.0
    case landscapeLeft = 180.0
    case upsideDownPortrait = 270.0
}

enum CameraState: Equatable, Sendable {
    case idle
    case requestingPermission
    case permissionGranted
    case configuring
    case ready
    case running
    case permissionDenied
    case restricted
    case failed(CameraSetupError)
}

enum CameraSetupError: Error, Equatable, Sendable {
    case deviceUnaviable
    case cannotCreateInput
    case cannotAddInput
    case cannotAddOutput
    case unknown(String)
}
