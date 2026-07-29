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
    var resultStream: AsyncStream<RecognitionResult> { get }
    func startObservingFramesAndProcess(sampleBufferStream: AsyncStream<CMSampleBuffer>)
}

final class RecognitionService: RecognitionServiceProtocol {
    private var isProcessing = false
    private let request = VNClassifyImageRequest()
    
    private var accumulator = RecognitionAccumulator()
    private let configuration: RecognitionConfiguration
    
    let resultStream: AsyncStream<RecognitionResult>
    private let resultContinuation: AsyncStream<RecognitionResult>.Continuation
    private var frameObservationTask: Task<Void, Never>?
    
    
    init(
        configuration: RecognitionConfiguration = RecognitionConfiguration(),
    ) {
        self.configuration = configuration
          
        let (stream, continuation) = AsyncStream.makeStream(of: RecognitionResult.self)
        self.resultStream = stream
        self.resultContinuation = continuation
    }
    
    deinit {
        resultContinuation.finish()
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
    
    func startObservingFramesAndProcess(sampleBufferStream: AsyncStream<CMSampleBuffer>) {
        guard frameObservationTask == nil else { return }
        
        frameObservationTask = Task { [weak self] in
            for await newFrame in sampleBufferStream {
                guard let self = self else { break }
                
                if let result = self.processFrame(newFrame) {
                    self.resultContinuation.yield(result)
                }
            }
        }
    }
}
