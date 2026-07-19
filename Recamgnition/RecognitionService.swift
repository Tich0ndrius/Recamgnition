//
//  RecognitionService.swift
//  Recamgnition
//
//  Created by Tykhon on 19.07.2026.
//
import Vision

struct RecognitionResult: Equatable {
    var identifier: String
    var confidence: Float
}

final class RecognitionService {
    private var isProcessing = false
    
    // MARK: Vision implementation
    func processFrame(_ pixelBuffer: CVPixelBuffer) -> RecognitionResult? {
        
        guard !isProcessing else { return nil}
        isProcessing = true
        defer { isProcessing = false }
        
        let request = VNClassifyImageRequest()
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer)
        
        try? handler.perform([request])
        
        guard let observation = request.results?.first as? VNClassificationObservation,
        observation.confidence > 0.65
        else { return nil }
        
        return RecognitionResult(
            identifier: observation.identifier,
            confidence: observation.confidence
        )
    }
}
