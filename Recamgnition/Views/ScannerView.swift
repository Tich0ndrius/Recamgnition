//
//  ScannerView.swift
//  Recamgnition
//
//  Created by Tykhon on 01.08.2026.
//

import SwiftUI

struct ScannerView: View {
    @State var cameraViewModel = CameraViewModel(
        cameraService: CameraService(),
        recognitionService: RecognitionService()
    )
    
    var body: some View {
        Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
    }
}

#Preview {
    ScannerView()
}
