//
//  TapMemoSharedStore.swift
//  TapMemo
//
//  Identificatori del gruppo condiviso fra app ed estensione widget.
//

import Foundation

enum TapMemoSharedStore {
    static let appGroupID = "group.com.smartapibox.tapmemo"
    static let storeName = "TapMemo.sqlite"

    /// Il controllo di Control Center / Action Button non può registrare da solo
    /// (servirebbe il microfono in background): lascia qui la richiesta e l'app
    /// la raccoglie al primo passaggio in primo piano.
    static let pendingRecordKey = "pendingRecordRequest"

    static var storeURL: URL? {
        FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: appGroupID)?
            .appendingPathComponent(storeName)
    }
}
