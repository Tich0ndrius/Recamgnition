//
//  RecognitionModel.swift
//  Recamgnition
//
//  Created by Tykhon on 28.07.2026.
//

import CoreFoundation

struct RecognitionResult: Equatable {
    private(set) var identifier: String
    private(set) var confidence: Float
}

struct RecognitionConfiguration {
    private(set) var minimumConfidence: Float = 0.65
    private(set) var requiredRepeats: Int = 3
}

struct RecognitionAccumulator {
    private var previousIdentifier: String?
    private var repeatCount: Int = 0
    private var lastProcessingTime: CFTimeInterval = 0
    private let processingInterval: CFTimeInterval = 0.1
    
    mutating func reset() {
        previousIdentifier = nil
        repeatCount = 0
    }
    
    mutating func process(
        _ rawResult: RecognitionResult,
        with configuration: RecognitionConfiguration,
        at currentTime: CFTimeInterval
    ) -> RecognitionResult? {
        
        guard currentTime - lastProcessingTime >= processingInterval else { return nil }
        
        // This should go before confidence validation for FPS limit to work properly
        lastProcessingTime = currentTime
        
        guard rawResult.confidence >= configuration.minimumConfidence else {
            reset()
            return nil }
        
        if rawResult.identifier == previousIdentifier {
            repeatCount += 1
        } else {
            previousIdentifier = rawResult.identifier
            repeatCount = 1
        }
        
        guard repeatCount >= configuration.requiredRepeats else { return nil }
        
        repeatCount = 0
        
        return rawResult
    }
}
    
    
