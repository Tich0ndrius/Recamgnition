//
//  ScanHistoryEntity.swift
//  Recamgnition
//
//  Created by Tykhon on 09.08.2026.
//

import Foundation
import SwiftData

@Model
final class ScanHistoryEntity: Identifiable {
    @Attribute(.unique)
    var id: UUID
    
    var content: String
//    var type: String
    var date: Date
    
    init(
        id: UUID = UUID(),
        content: String,
//        type: String,
        date: Date
    ) {
        self.id = id
        self.content = content
//        self.type = type
        self.date = date
    }
}
