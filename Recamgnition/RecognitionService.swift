//
//  RecognitionService.swift
//  Recamgnition
//
//  Created by Tykhon on 19.07.2026.
//
import Vision

protocol RecognitionServiceProtocol {
    func processFrame(_ sampleBuffer: CMSampleBuffer) -> RecognitionResult?
}

struct RecognitionResult: Equatable {
    var identifier: String
    var confidence: Float
}

final class RecognitionService: RecognitionServiceProtocol {
    private var isProcessing = false
    private var previousIdentifier: String?
    private var repeatCount = 0
    private let request = VNClassifyImageRequest()
    private let requiredRepeats = 3
    private let minimumConfidence: Float = 0.65
    
    // MARK: Vision implementation
    func processFrame(_ sampleBuffer: CMSampleBuffer) -> RecognitionResult? {
        
        guard !isProcessing else { return nil}
        isProcessing = true
        defer { isProcessing = false }
        
        guard let pixelBuffer: CVPixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return nil }
        
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer)
        
        do {
            try handler.perform([request])
        } catch {
            return nil
        }
        
        guard let observation = request.results?.first as? VNClassificationObservation,
        observation.confidence > minimumConfidence
        else { return nil }
        
        if observation.identifier == previousIdentifier {
            repeatCount += 1
        } else {
            previousIdentifier = observation.identifier
            repeatCount = 1
        }
        
        guard repeatCount >= requiredRepeats else { return nil }
        
        repeatCount = 0
        
        return RecognitionResult(
                identifier: observation.identifier,
                confidence: observation.confidence
        )
    }
}
