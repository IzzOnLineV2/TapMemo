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
    // ModelContainer con App Group per condivisione con widget
    static let sharedModelContainer: ModelContainer = {
        let appGroupID = "group.com.smartapibox.tapmemo"
        
        // Prova ad usare App Group per condivisione con widget
        if let groupURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: appGroupID
        ) {
            let storeURL = groupURL.appendingPathComponent("TapMemo.sqlite")
            let config = ModelConfiguration(url: storeURL)
            
            do {
                let container = try ModelContainer(for: MemoItem.self, configurations: config)
                print("✅ App Group configurato correttamente!")
                print("✅ Database condiviso: \(storeURL.path)")
                return container
            } catch {
                print("⚠️ Failed to create shared container: \(error)")
            }
        } else {
            print("⚠️ App Group '\(appGroupID)' non trovato!")
            print("⚠️ Verifica Signing & Capabilities → App Groups")
        }
        
        // Fallback: usa container di default (senza widget sharing)
        print("⚠️ Usando container locale (widget non vedrà i dati)")
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
