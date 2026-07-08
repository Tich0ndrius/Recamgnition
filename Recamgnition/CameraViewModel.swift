//
//  CameraViewModel.swift
//  Recamgnition
//
//  Created by Tykhon on 16.06.2026.
//

//import CoreImage
import Observation
import AVFoundation
import Vision

@Observable final class CameraViewModel: NSObject {
//    var frame: CGImage?
//    private let context = CIContext()
    private let sessionQueue = DispatchQueue(label: "sessionQueue")
    let captureSession = AVCaptureSession()
    var currentObject = ""
    var confidence: Float = 0.0
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
        guard await isAuthorized else { return }
        captureSession.beginConfiguration()
        
        let videoOutput = AVCaptureVideoDataOutput()
        guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else { return }
        guard let videoDeviceInput = try? AVCaptureDeviceInput(device: videoDevice) else { return }
        guard captureSession.canAddInput(videoDeviceInput) else { return }
        captureSession.addInput(videoDeviceInput)
        
        videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "sampleBufferQueue"))
        guard captureSession.canAddOutput(videoOutput) else { return }
        captureSession.addOutput(videoOutput)
        
//        deprecated
//        videoOutput.connection(with: .video)?.videoOrientation = .portrait
        if let connection = videoOutput.connection(with: .video) {
            let targetAngle: CGFloat = TargetAngle.portrait.rawValue
            if connection.isVideoRotationAngleSupported(targetAngle) {
                connection.videoRotationAngle = targetAngle
            }
        }
        
        captureSession.commitConfiguration()
        startSession()
    }
    
    func startSession() {
        sessionQueue.async { [weak self] in
            self?.captureSession.startRunning()
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
    
    
//    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
//        guard let cgImage = imageFromSampleBuffer(sampleBuffer: sampleBuffer) else { return }
//        
//        DispatchQueue.main.async { [weak self] in
//            self?.frame = cgImage
//        }
//    }
//    
//    private func imageFromSampleBuffer(sampleBuffer: CMSampleBuffer) -> CGImage? {
//        guard let imageBuffer: CVImageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return nil }
//        let ciImage: CIImage = CIImage(cvImageBuffer: imageBuffer)
//        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else { return nil }
//        return cgImage
//    }
}

enum TargetAngle: CGFloat {
    case landscapeRight = 0.0
    case portrait = 90.0
    case landscapeLeft = 180.0
    case upsideDownPortrait = 270.0
}

struct RecognitionHistory {
    let name: String
    let confidence: Float
    let date: Date
}
