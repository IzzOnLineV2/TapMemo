//
//  AppIssue.swift
//  TapMemo
//
//  Parte 3 · 3h — niente alert di sistema: l'errore è una card in linea, quindi
//  resta leggibile, si può rileggere e non blocca l'app. Ogni messaggio dice
//  cosa non funziona, cosa succede ai dati e qual è l'azione.
//

import Foundation

enum AppIssue: Identifiable, Equatable {
    case microphoneDenied
    case speechDenied
    case calendarDenied
    case remindersDenied
    case notUnderstood
    case recordingUnavailable(String)
    case eventKitFailed(String)

    var id: String {
        switch self {
        case .microphoneDenied:            "mic"
        case .speechDenied:                "speech"
        case .calendarDenied:              "calendar"
        case .remindersDenied:             "reminders"
        case .notUnderstood:               "notunderstood"
        case .recordingUnavailable(let d): "unavailable-\(d)"
        case .eventKitFailed(let d):       "eventkit-\(d)"
        }
    }

    var title: String {
        switch self {
        case .microphoneDenied:     String(localized: "Il microfono è disattivato")
        case .speechDenied:         String(localized: "Dettatura non autorizzata")
        case .calendarDenied:       String(localized: "Calendario negato")
        case .remindersDenied:      String(localized: "Promemoria negati")
        case .notUnderstood:        String(localized: "Non ho capito")
        case .recordingUnavailable: String(localized: "Registrazione non disponibile")
        case .eventKitFailed:       String(localized: "Evento non creato")
        }
    }

    var message: String {
        switch self {
        case .microphoneDenied:
            String(localized: "Senza microfono TapMemo non può ascoltarti. L'audio resta sul telefono: non viene registrato né inviato da nessuna parte.")
        case .speechDenied:
            String(localized: "Posso registrare, ma non trascrivere. La trascrizione avviene sul telefono: attivala per creare i memo.")
        case .calendarDenied:
            String(localized: "Il memo è salvato in TapMemo; l'evento no. Autorizza il calendario per far creare gli eventi a TapMemo.")
        case .remindersDenied:
            String(localized: "Il memo è salvato in TapMemo; il promemoria no. Autorizza Promemoria per completare l'operazione.")
        case .notUnderstood:
            String(localized: "Non ho sentito niente di comprensibile. Nessun memo è stato creato: tocca e parla di nuovo.")
        case .recordingUnavailable(let detail):
            String(localized: "Non riesco ad avviare la registrazione. Riprova fra un momento. (\(detail))")
        case .eventKitFailed(let detail):
            String(localized: "Il memo è salvato in TapMemo, ma l'evento non è stato creato. (\(detail))")
        }
    }

    var symbol: String {
        switch self {
        case .notUnderstood: "waveform.slash"
        default:             "exclamationmark.triangle"
        }
    }

    /// Le card di permesso portano a Impostazioni; le altre si chiudono e basta.
    var opensSettings: Bool {
        switch self {
        case .microphoneDenied, .speechDenied, .calendarDenied, .remindersDenied: true
        default: false
        }
    }

    var dismissTitle: String {
        opensSettings ? String(localized: "Non ora") : String(localized: "Ho capito")
    }
}
