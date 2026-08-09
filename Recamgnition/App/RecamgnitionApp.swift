//
//  RecamgnitionApp.swift
//  Recamgnition
//
//  Created by Tykhon on 16.06.2026.
//

import SwiftUI
import SwiftData

@main
@MainActor
struct RecamgnitionApp: App {

    private let container: ModelContainer

//    let container: ModelContainer = {
//        let schema = Schema([ScanHistoryEntity.self])
//        
//        do {
//            return try ModelContainer(for: schema, configurations: [])
//        } catch {
//            fatalError("Could not create MdoelContainer: \(error.localizedDescription)")
//        }
//    }()
    
    @State private var cameraViewModel: CameraViewModel
    
    init() {
        do {
            let container = try ModelContainer(for: ScanHistoryEntity.self)
            let repository = ScanHistoryRepository(context: container.mainContext)
            
            self.container = container
            self._cameraViewModel = State(
                initialValue: CameraViewModel(
                    cameraService: CameraService(),
                    recognitionService: RecognitionService(),
                    scanHistoryRepository: repository
                )
            )
        } catch {
            fatalError("Failed to create ModelContainer: \(error.localizedDescription)")
        }
    }
    
    
    var body: some Scene {
        WindowGroup {
            CameraView(
                cameraViewModel: cameraViewModel
            )
        }
        .modelContainer(container)
    }
}
