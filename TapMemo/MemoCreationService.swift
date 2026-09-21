//
//  MemoCreationService.swift
//  TapMemo
//
//  Created by Stefania Izzo on 03/03/26.
//
//  Redesign 3d/3e — l'esito non è più un banner verde generico: il servizio
//  pubblica cosa è stato creato e quando, e tiene aperta una finestra di
//  annullamento che elimina davvero l'evento appena creato.
//

import Foundation
import SwiftData
import Combine
import WidgetKit
import EventKit

// MARK: - Esito di una creazione

struct MemoConfirmation: Identifiable, Equatable {
    enum Outcome: Equatable {
        /// Il memo conteneva una data: l'evento è in Calendario.
        case eventCreated
        /// Nessuna data riconosciuta: il memo resta in TapMemo.
        case savedLocally
    }

    let id = UUID()
    let memo: MemoItem
    let outcome: Outcome

    static func == (lhs: MemoConfirmation, rhs: MemoConfirmation) -> Bool { lhs.id == rhs.id }
}

@MainActor
final class MemoCreationService: ObservableObject {
    private let eventKit = EventKitService()

    /// Card in linea per i fallimenti (3h). Ha sostituito `lastError: String?`.
    @Published var issue: AppIssue?
    /// Trascrizione in lavorazione: alimenta la card «Sto capendo quando…» (3d).
    @Published private(set) var processingTranscript: String?
    /// Foglio di conferma (3e).
    @Published var confirmation: MemoConfirmation?

    var isProcessing: Bool { processingTranscript != nil }

    // MARK: - Dalla voce al memo

    func handleNewTranscript(_ text: String, context: ModelContext) async {
        processingTranscript = text
        issue = nil
        defer { processingTranscript = nil }

        let parsed = MemoParser.parse(text)

        let memo = MemoItem(
            originalText: text,
            normalizedTitle: parsed.title,
            dueAt: parsed.dueAt
        )
        context.insert(memo)

        // Regola dell'app: se ha data/ora → evento in Calendario, automatico.
        guard let due = parsed.dueAt else {
            Haptics.success()
            reloadWidgets()
            confirmation = MemoConfirmation(memo: memo, outcome: .savedLocally)
            return
        }

        do {
            let id = try await eventKit.createCalendarEvent(
                title: parsed.title,
                date: due,
                isAllDay: isAllDay(due)
            )
            memo.calendarIdentifier = id
            Haptics.success()
            reloadWidgets()
            confirmation = MemoConfirmation(memo: memo, outcome: .eventCreated)

        } catch {
            // Il memo resta comunque salvato: lo dice la card.
            issue = calendarIssue(from: error)
            Haptics.error()
            reloadWidgets()
        }
    }

    // MARK: - Azioni sulle righe

    func saveAsReminder(_ memo: MemoItem) async {
        do {
            let id = try await eventKit.createReminder(title: memo.normalizedTitle, due: memo.dueAt)
            memo.reminderIdentifier = id
            Haptics.success()
            reloadWidgets()
        } catch {
            issue = remindersIssue(from: error)
            Haptics.error()
        }
    }

    func saveAsCalendarEvent(_ memo: MemoItem, date: Date) async {
        do {
            let id = try await eventKit.createCalendarEvent(
                title: memo.normalizedTitle,
                date: date,
                isAllDay: isAllDay(date)
            )
            memo.calendarIdentifier = id
            memo.dueAt = date
            Haptics.success()
            reloadWidgets()
        } catch {
            issue = calendarIssue(from: error)
            Haptics.error()
        }
    }

    func deleteMemo(_ item: MemoItem, context: ModelContext) async {
        if let calId = item.calendarIdentifier {
            try? await eventKit.deleteEvent(identifier: calId)
        }
        if let remId = item.reminderIdentifier {
            try? await eventKit.deleteReminder(identifier: remId)
        }

        context.delete(item)
        reloadWidgets()
    }

    // MARK: - Foglio di conferma (3e)

    /// «Annulla» entro la finestra di 4 s: elimina l'evento appena creato e il memo.
    func undo(_ confirmation: MemoConfirmation, context: ModelContext) async {
        await deleteMemo(confirmation.memo, context: context)
        self.confirmation = nil
        Haptics.warning()
    }

    /// «Cambia ora»: sposta l'evento invece di ricrearlo, così l'id resta valido.
    func changeTime(of memo: MemoItem, to date: Date) async {
        memo.dueAt = date

        guard let calId = memo.calendarIdentifier else {
            reloadWidgets()
            return
        }

        do {
            try await eventKit.updateEvent(identifier: calId, date: date, isAllDay: isAllDay(date))
            Haptics.success()
            reloadWidgets()
        } catch {
            issue = .eventKitFailed(error.localizedDescription)
            Haptics.error()
        }
    }

    // MARK: - Sync con EventKit

    func syncWithEventKit(memos: [MemoItem], context: ModelContext) async {
        var changed = false

        for memo in memos {
            if let calId = memo.calendarIdentifier {
                let exists = await eventKit.eventExists(identifier: calId)
                if !exists {
                    memo.calendarIdentifier = nil
                    changed = true
                }
            }
            if let remId = memo.reminderIdentifier {
                let exists = await eventKit.reminderExists(identifier: remId)
                if !exists {
                    memo.reminderIdentifier = nil
                    changed = true
                }
            }
        }

        if changed { reloadWidgets() }
    }

    // MARK: - Interni

    private func isAllDay(_ date: Date) -> Bool {
        Calendar.current.isDate(date,
                                equalTo: Calendar.current.startOfDay(for: date),
                                toGranularity: .minute)
    }

    private func reloadWidgets() {
        WidgetCenter.shared.reloadAllTimelines()
    }

    /// EventKitService segnala l'accesso negato con il codice 1 (calendario) e 2
    /// (promemoria): distinguere il permesso dal guasto cambia l'azione offerta.
    private func calendarIssue(from error: Error) -> AppIssue {
        let nsError = error as NSError
        if nsError.domain == "TapMemo" && nsError.code == 1 { return .calendarDenied }
        if nsError.domain == EKErrorDomain { return .calendarDenied }
        return .eventKitFailed(error.localizedDescription)
    }

    private func remindersIssue(from error: Error) -> AppIssue {
        let nsError = error as NSError
        if nsError.domain == "TapMemo" && nsError.code == 2 { return .remindersDenied }
        if nsError.domain == EKErrorDomain { return .remindersDenied }
        return .eventKitFailed(error.localizedDescription)
    }
}
