//
//  RecognitionService.swift
//  Recamgnition
//
//  Created by Tykhon on 19.07.2026.
//
import Vision
import QuartzCore

protocol RecognitionServiceProtocol {
    func processFrame(_ sampleBuffer: CMSampleBuffer) -> RecognitionResult?
}

final class RecognitionService: RecognitionServiceProtocol {
    private var isProcessing = false
    private let request = VNClassifyImageRequest()
    
    private var accumulator = RecognitionAccumulator()
    private let configuration: RecognitionConfiguration
    
    init(configuration: RecognitionConfiguration = RecognitionConfiguration()) {
        self.configuration = configuration
    }
    
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
        
        guard let observation = request.results?.first as? VNClassificationObservation else { return nil }
        
        let rawResult = RecognitionResult(identifier: observation.identifier, confidence: observation.confidence)
        let currentTime = CACurrentMediaTime()
        return accumulator.process(rawResult, with: configuration, at: currentTime)
    }
}
