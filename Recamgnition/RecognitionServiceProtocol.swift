//
//  RecognitionServiceProtocol.swift
//  Recamgnition
//
//  Created by Tykhon on 21.07.2026.
//

import AVFoundation

protocol RecognitionServiceProtocol {
    func processFrame(_ sampleBuffer: CMSampleBuffer) -> RecognitionResult?
}
