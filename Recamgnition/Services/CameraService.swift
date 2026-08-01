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
    
    var currentMode: CaptureMode { get set }
    
    func toggleCaptureMode()
    func startSession()
    func stopSession()
    func setUpCaptureSession() async
}

final class CameraService: NSObject, CameraServiceProtocol {
    
    private let sessionQueue = DispatchQueue(label: "camera.session.queue")
    
//    let captureModeStream: AsyncStream<CaptureMode>
//    private let captureModeContinuation: AsyncStream<CaptureMode>.Continuation
    var currentMode: CaptureMode = .recognition
    
    let cameraStateStream: AsyncStream<CameraState>
    private let stateContinuation: AsyncStream<CameraState>.Continuation
    private(set) var currentState: CameraState = .idle
    
    let sampleBufferStream: AsyncStream<CMSampleBuffer>
    private let frameContinuation: AsyncStream<CMSampleBuffer>.Continuation
    
    let captureSession = AVCaptureSession()
    private var videoDevice: AVCaptureDevice?
    
    private(set) var isAuthorized: Bool = false
    var isTorchOn: Bool = false
    var isScanning: Bool = false
    var scannedResult: ScannedResult?
    
    
    
    override init() {
        let (stateStream, stateContinuation) = AsyncStream.makeStream(of: CameraState.self, bufferingPolicy: .bufferingNewest(1))
        self.cameraStateStream = stateStream
        self.stateContinuation = stateContinuation
        
        let (frameStream, frameContinuation) = AsyncStream.makeStream(of: CMSampleBuffer.self, bufferingPolicy: .bufferingNewest(1))
        self.sampleBufferStream = frameStream
        self.frameContinuation = frameContinuation
        
//        let (modeStream, modeContinuation) = AsyncStream.makeStream(of: CaptureMode.self, bufferingPolicy: .bufferingNewest(1))
//        self.captureModeStream = modeStream
//        self.captureModeContinuation = modeContinuation
        
        super .init()
        
        self.stateContinuation.yield(.idle)
//        self.captureModeContinuation.yield(.recognition)
    }
    
    deinit {
        stateContinuation.finish()
        frameContinuation.finish()
//        captureModeContinuation.finish()
    }
    
    
    func toggleTorch() {
        guard let device = videoDevice, device.hasTorch else { return }
        try? device.lockForConfiguration()
        isTorchOn.toggle()
        device.torchMode = isTorchOn ? .on : .off
        device.unlockForConfiguration()
    }
    
    func resetScannedResult() {
        isScanning = false
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
    
    func toggleCaptureMode () {
        currentMode = (currentMode == .recognition) ? .codes : .recognition
//        captureModeContinuation.yield(currentMode)
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
        
        guard let videoDevice = AVCaptureDevice.default(
            .builtInWideAngleCamera,
            for: .video,
            position: .back
        ) else {
            throw CameraSetupError.deviceUnaviable
        }
        
        self.videoDevice = videoDevice
        
        guard let videoDeviceInput = try? AVCaptureDeviceInput(device: videoDevice) else {
            throw CameraSetupError.cannotCreateInput
        }
        
        guard captureSession.canAddInput(videoDeviceInput) else {
            throw CameraSetupError.cannotAddInput
        }
        captureSession.addInput(videoDeviceInput)
        
        //MARK: Recognition output setup
        let videoOutput = AVCaptureVideoDataOutput()
        videoOutput.alwaysDiscardsLateVideoFrames = true
        
        videoOutput.setSampleBufferDelegate(
            self,
            queue: DispatchQueue(label: "sample.buffer.queue")
        )
        
        guard captureSession.canAddOutput(videoOutput) else {
            throw CameraSetupError.cannotAddOutput
        }
        
        captureSession.addOutput(videoOutput)
        
        //MARK: Scanner output setup
        let scannerOutput = AVCaptureMetadataOutput()
        
        scannerOutput.setMetadataObjectsDelegate(
            self,
            queue: DispatchQueue(label: "metadata.queue")
        )
        
        guard captureSession.canAddOutput(scannerOutput) else {
            throw CameraSetupError.cannotAddOutput
        }
        
        captureSession.addOutput(scannerOutput)
        scannerOutput.metadataObjectTypes = [.qr, .code128, .code39, .ean13, .ean8, .upce]
        
        
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
            self.isScanning = true
        }
    }
    
    func stopSession() {
        transition(to: .ready)
        
        sessionQueue.async {
            guard self.captureSession.isRunning else { return }
            
            self.captureSession.stopRunning()
            self.isScanning = false
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
        guard currentMode == .recognition else { return }
        frameContinuation.yield(sampleBuffer)
    }
}

extension CameraService: AVCaptureMetadataOutputObjectsDelegate {
    func metadataOutput(
        _ output: AVCaptureMetadataOutput,
        didOutput metadataObjects: [AVMetadataObject],
        from connection: AVCaptureConnection
    ) {
        guard currentMode == .codes else { return }
        guard scannedResult == nil else { return }
        guard let metadataObject = metadataObjects.first as? AVMetadataMachineReadableCodeObject else { return }
        guard let readableObject = metadataObject.stringValue else { return }
        
        AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
        
        if let url = URL(string: readableObject),
           (url.scheme == "https" || url.scheme == "http"),
           url.host != nil {
            scannedResult = .url(url)
        } else {
            scannedResult = .text(readableObject)
        }
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

enum CaptureMode: Equatable, Sendable {
    case recognition
    case codes
    
    var iconName: String {
        switch self {
        case .recognition:
            return "camera.viewfinder"
        case .codes:
            return "qrcode.viewfinder"
        }
    }
}

enum ScannedResult: Equatable, Sendable {
    case url(URL)
    case text(String)
    
    var rawString: String {
        switch self {
        case .url(let url):
            return url.absoluteString
        case .text(let text):
            return text
        }
    }
}

enum CameraSetupError: Error, Equatable, Sendable {
    case deviceUnaviable
    case cannotCreateInput
    case cannotAddInput
    case cannotAddOutput
    case unknown(String)
}
