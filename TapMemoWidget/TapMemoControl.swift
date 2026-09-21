//
//  TapMemoControl.swift
//  TapMemoWidget
//
//  Parte 4 · 5c — il controllo per Control Center e Action Button.
//
//  Nota: il controllo non può registrare da solo restando in background (non
//  avremmo il microfono), quindi apre l'app e lascia la richiesta nel gruppo
//  condiviso; l'app la raccoglie e parte l'ascolto.
//

import AppIntents
import SwiftUI
import WidgetKit

struct StartRecordingIntent: AppIntent {
    static var title: LocalizedStringResource = "Registra un memo"
    static var description = IntentDescription("Apre TapMemo e avvia subito l'ascolto.")
    static var openAppWhenRun: Bool = true

    func perform() async throws -> some IntentResult {
        UserDefaults(suiteName: TapMemoSharedStore.appGroupID)?
            .set(true, forKey: TapMemoSharedStore.pendingRecordKey)
        return .result()
    }
}

struct TapMemoRecordControl: ControlWidget {
    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(kind: "com.smartapibox.tapmemo.control.record") {
            ControlWidgetButton(action: StartRecordingIntent()) {
                Label("Parla", systemImage: "mic.fill")
            }
        }
        .displayName("Registra un memo")
        .description("Avvia un memo vocale senza cercare l'app.")
    }
}
