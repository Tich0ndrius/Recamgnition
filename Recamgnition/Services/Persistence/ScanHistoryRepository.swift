//
//  ScanHistoryRepository.swift
//  Recamgnition
//
//  Created by Tykhon on 09.08.2026.
//

import Foundation
import SwiftData

protocol ScanHistoryRepositoryProtocol {
    func add(_ result: ScannedResult)
}


@MainActor
final class ScanHistoryRepository: ScanHistoryRepositoryProtocol {
    private let context: ModelContext
    
    init(context: ModelContext) {
        self.context = context
    }
    
    
    func add(_ result: ScannedResult) {
        let entity = ScanHistoryEntity(
            content: result.rawString,
//            type: <#T##String#>,
            date: .now
            )
        
        context.insert(entity)
    }
    
}

#if DEBUG

import SwiftUI

struct MockSwiftDataTrait: PreviewModifier {
    
    func body(content: Content, context: ModelContainer) -> some View {
        content.modelContainer(context)
    }
    
    static func makeSharedContext() async throws -> ModelContainer {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: ScanHistoryEntity.self, configurations: config)
        
        let sampleResults: [(result: ScannedResult, date: Date)] = [
            (.text("Mock text"), .now),
            (.text("Second mock text"), Calendar.current.date(byAdding: .day, value: -3, to: .now)!),
            (.url(URL(string: "https://google.com")!), Calendar.current.date(byAdding: .hour, value: -12, to: .now)!),
            (.url(URL(string: "https://apple.com")!), Calendar.current.date(byAdding: .day, value: -2, to: .now)!)
        ]
    
        for item in sampleResults {
            let entity = ScanHistoryEntity(content: item.result.rawString, date: item.date)
            container.mainContext.insert(entity)
        }
        
        return container
    }
}

extension PreviewTrait where T == Preview.ViewTraits {
    @MainActor static var mockScanHistory: Self = .modifier(MockSwiftDataTrait())
}

@MainActor
final class ScanHistoryRepositoryMock: ScanHistoryRepositoryProtocol {
    var savedResults: [ScanHistoryEntity] = []
  
    init(initialHistory: [ScanHistoryEntity] = []) {
        self.savedResults = initialHistory
    }
    
    func add(_ result: ScannedResult) {
        let entity = ScanHistoryEntity(content: result.rawString, date: .now)
        savedResults.append(entity)
    }
}

#endif
