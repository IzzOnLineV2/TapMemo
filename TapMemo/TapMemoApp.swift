//
//  TapMemoApp.swift
//  TapMemo
//
//  Created by Stefania Izzo on 03/03/26.
//

import SwiftUI
import SwiftData

@main
struct TapMemoApp: App {
    // ModelContainer sul gruppo condiviso, così il widget legge gli stessi dati.
    static let sharedModelContainer: ModelContainer = {
        if let storeURL = TapMemoSharedStore.storeURL {
            let config = ModelConfiguration(url: storeURL)
            do {
                return try ModelContainer(for: MemoItem.self, configurations: config)
            } catch {
                print("⚠️ Store condiviso non apribile: \(error)")
            }
        } else {
            print("⚠️ App Group '\(TapMemoSharedStore.appGroupID)' non trovato — Signing & Capabilities → App Groups")
        }

        // Fallback locale: l'app funziona, il widget non vedrà i dati.
        do {
            return try ModelContainer(for: MemoItem.self)
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(Self.sharedModelContainer)
    }
}
