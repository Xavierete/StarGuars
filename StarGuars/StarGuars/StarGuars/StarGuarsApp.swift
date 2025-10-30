//
//  StarGuarsApp.swift
//  StarGuars
//
//  Created by Xavier Moreno on 10/3/25.
//

import SwiftUI
import SwiftData

@main
struct StarGuarsApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Item.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
    
    // Creamos una instancia del ViewModel como StateObject
    @StateObject private var viewModel = ViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(viewModel) // Pasamos el ViewModel como environment object
                .modelContainer(sharedModelContainer)
                .onAppear {
                    let modelContext = ModelContext(sharedModelContainer)
                    viewModel.setModelContext(modelContext)
                }
        }
    }
}
