//
//  ScannerView.swift
//  Recamgnition
//
//  Created by Tykhon on 01.08.2026.
//

import SwiftUI

struct ScannerView: View {
    let scannedResult: ScannedResult?
    var onReset: () -> Void
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                
                let frameSize = min(geo.size.width, geo.size.height) * 0.66
                ZStack {
                    ZStack {
                        Color.black.opacity(0.5)
                            .mask(
                                Rectangle()
                                    .overlay(RoundedRectangle(cornerRadius: 16)
                                        .frame(width: frameSize, height: frameSize)
                                        .blendMode(.destinationOut)
                                    )
                                    .compositingGroup()
                            )
                        
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white.opacity(0.15), lineWidth: 1)
                            .frame(width: frameSize, height: frameSize)
                    }
                    .ignoresSafeArea()
                    
                    VStack {
                        Spacer()
                        if scannedResult == nil {
                            Text("Scan the code")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundStyle(.white)
                                .padding(.bottom, geo.size.height * 0.25)
                        }
                    }
                }
                
            }
            
            if let result = scannedResult {
                VStack {
                    Spacer()
                    ScanResultView(result: result) {
                        onReset()
                    }
                    .padding(.horizontal, 10)
                }
                .ignoresSafeArea(edges: .bottom)
                .transition(.move(edge: .bottom))
                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: scannedResult != nil)
            }
        }
    }
}

#Preview {
    ScannerView(scannedResult: .url(URL(string: "https://google.com")!)) {
        //
    }
}
