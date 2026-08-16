//
//  ScanResultView.swift
//  Recamgnition
//
//  Created by Tykhon on 01.08.2026.
//

import SwiftUI

struct ScanResultView: View {
    let result: ScannedResult
    var onReset: () -> Void
    
    @State private var appeared = false
    @State private var copied = false
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(iconBackground)
                        .frame(width: 48, height: 48)
                    Image(systemName: iconName)
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundStyle(iconColor)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(typeLabel)
                        .font(.footnote)
                        .fontWeight(.medium)
                        .foregroundStyle(.white.opacity(0.5))
                        .textCase(.uppercase)
                        .tracking(0.8)
                    Text("Data recieved")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.white)
                }
                Spacer()
                ZStack {
                    Circle().fill(.green.opacity(0.2))
                        .frame(width: 32, height: 32)
                    Image(systemName: "checkmark")
                        .font(.footnote)
                        .fontWeight(.bold)
                        .foregroundStyle(.green)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 10)
            
            Divider()
                .background(Color.white.opacity(0.2))
                .padding(.vertical, 16)
            
            ScrollView {
                Text(result.rawString)
                    .font(.subheadline)
                    .fontWeight(.regular)
                    .fontDesign(.monospaced)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .foregroundStyle(.white.opacity(0.9))
                    .padding(.horizontal, 20)
            }
            .frame(maxHeight: 120)
            
            Spacer().frame(height: 20)
            
            VStack {
                mainButton
                HStack {
                    copyButton
                    scanAgainButton
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 36)
            
        }
        .background(
            RoundedRectangle(cornerRadius: 30)
                .fill(.black.opacity(0.85))
                .overlay(content: {
                    RoundedRectangle(cornerRadius: 30)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                })
        )
        .offset(y: appeared ? 0 : 300)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                appeared = true
            }
        }
        .toolbar(.hidden, for: .tabBar)
    }
}

extension ScanResultView {
    
    @ViewBuilder
    private var mainButton: some View {
        switch result {
        case .url(let url):
            Button {
                UIApplication.shared.open(url)
            } label: {
                Label("Open link", systemImage: "safari.fill")
                    .font(.callout)
                    .fontWeight(.semibold)
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(.cyan)
                    .clipShape(RoundedRectangle(cornerRadius: 15))
            }
        case .text:
            ShareLink(item: result.rawString) {
                Label("Share text", systemImage: "square.and.arrow.up")
                    .font(.callout)
                    .fontWeight(.semibold)
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(.cyan)
                    .clipShape(RoundedRectangle(cornerRadius: 15))
            }
        }
    }
    
    private var copyButton: some View {
        Button {
            UIPasteboard.general.string = result.rawString
            withAnimation { copied = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                withAnimation { copied = false }
            }
        } label: {
            Label(copied ? "Copied" : "Copy", systemImage: copied ? "checkmark" : "doc.on.doc")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(.white.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
    
    private var scanAgainButton: some View {
        Button {
            onReset()
        } label: {
            Label("Scan again", systemImage: "qrcode.viewfinder")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(.white.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
    
    private var iconName: String {
        switch result {
        case .url: "link"
        case .text: "text.alignleft"
        }
    }
    private var typeLabel: LocalizedStringKey {
        switch result {
        case .url: "Link"
        case .text: "Text"
        }
    }
    private var iconBackground: Color {
        switch result {
        case .url: .cyan.opacity(0.2)
        case .text: .purple.opacity(0.2)
        }
    }
    private var iconColor: Color {
        switch result {
        case .url: .cyan
        case .text: .purple
        }
    }
}

#Preview("English") {
    ScanResultView(result: .url(URL(string: "https://www.google.com")!), onReset: {
        //
    })
    .environment(\.locale, Locale(identifier: "EN"))
}

#Preview("Russian") {
    ScanResultView(result: .url(URL(string: "https://www.google.com")!), onReset: {
        //
    })
    .environment(\.locale, Locale(identifier: "RU"))
}

#Preview("ForText") {
    ScanResultView(result: .text("Hello, world!"), onReset: {
        //
    })
}
