//
//  RecognitionView.swift
//  Recamgnition
//
//  Created by Tykhon on 01.08.2026.
//

import SwiftUI

struct RecognitionView: View {
    let currentRecognition: RecognitionResult?
    
    var body: some View {
        VStack {
            Spacer()
            
            if let recognition = currentRecognition {
                Text("\(recognition.displayedName), \(Int(recognition.confidence * 100))%")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(.white)
                .padding()
                .background(RoundedRectangle(cornerRadius: 10).fill(Color.cyan.opacity(0.7)))
                .padding()
            } else {
                Text("Point the camera to the object...")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 10).fill(Color.cyan.opacity(0.7)))
                    .padding()
            }
        }
    }
}

#Preview("English") {
    RecognitionView(currentRecognition: RecognitionResult(identifier: "adult_cat", confidence: 0.98))
        .environment(\.locale, Locale(identifier: "EN"))
}

#Preview("Russian") {
    RecognitionView(currentRecognition: RecognitionResult(identifier: "adult_cat", confidence: 0.98))
        .environment(\.locale, Locale(identifier: "RU"))
}
