//
//  HistoryView.swift
//  Recamgnition
//
//  Created by Tykhon on 09.08.2026.
//

import SwiftUI
import SwiftData

struct HistoryView: View {
    @Environment(\.modelContext) var context
    @Query(sort: \ScanHistoryEntity.date, order: .reverse) var history: [ScanHistoryEntity]
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(history) { history in
                    HistoryCell(history: history)
                }
                .onDelete {
                    indexSet in
                    for index in indexSet {
                        context.delete(history[index])
                    }
                }
            }
            .navigationTitle("History")
            .navigationBarTitleDisplayMode(.large)
            .overlay {
                if history.isEmpty {
                    ContentUnavailableView(
                        "No history",
                        systemImage: "list.bullet.rectangle.portrait",
                        description: Text("Start scanning codes")
                    )
                    .offset(y: -60)
                }
            }
        }
    }
}

struct HistoryCell: View {
    let history: ScanHistoryEntity
    
    var body: some View {
        HStack {
            Text(history.date, format: .dateTime.month(.abbreviated).day().hour().minute())
                .frame(width: 120, alignment: .leading)
            Text(history.content)
        }
    }
}

#Preview {
    HistoryView()
}
