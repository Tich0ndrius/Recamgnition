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
