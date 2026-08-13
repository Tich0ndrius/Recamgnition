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

@MainActor
final class ScanHistoryRepositoryMock: ScanHistoryRepositoryProtocol {
    var savedResults: [ScanHistoryEntity] = []
    
    init(dataToSave: [ScannedResult] = [
        .text("Mock text"),
        .url(URL(string: "https://google.com")!),
        .url(URL(string: "https://google.com")!)
    ]) {
        self.savedResults = dataToSave.map { stringData in
            ScanHistoryEntity(content: stringData.rawString, date: .now)}
    }
    
    func add(_ result: ScannedResult) {
        savedResults.append(ScanHistoryEntity(content: result.rawString, date: .now))
    }
}

#endif
