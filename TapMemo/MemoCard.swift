//
//  MemoCard.swift
//  TapMemo
//
//  Parte 3 · 3a/3f/3g — la riga memo come card, con un solo badge di stato e le
//  azioni esposte anche fuori dallo swipe (che con VoiceOver non è utilizzabile).
//

import SwiftUI

struct MemoCard: View {
    let memo: MemoItem

    @Environment(\.dynamicTypeSize) private var typeSize

    private var transcript: String? {
        // La trascrizione si mostra solo se aggiunge qualcosa al titolo.
        guard memo.originalText.lowercased() != memo.normalizedTitle.lowercased() else { return nil }
        return memo.originalText
    }

    var body: some View {
        VStack(alignment: .leading, spacing: TMSpace.s) {
            if typeSize.isAccessibilitySize {
                // Alle taglie accessibilità il badge passa sotto e va a piena
                // larghezza: la card cresce in altezza, niente troncamenti.
                Text(memo.normalizedTitle)
                    .font(.headline)
                dueLine
                transcriptLine
                badge
            } else {
                HStack(alignment: .firstTextBaseline, spacing: TMSpace.s) {
                    Text(memo.normalizedTitle)
                        .font(.headline)
                    Spacer(minLength: TMSpace.s)
                    badge
                }
                dueLine
                transcriptLine
            }
        }
        .padding(TMSpace.rowPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .tmCardSurface()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(memo.accessibilityDescription)
        .accessibilityValue(transcript ?? "")
    }

    @ViewBuilder
    private var badge: some View {
        MemoStatusBadge(destination: memo.destination,
                        secondary: memo.hasSecondaryDestination)
    }

    @ViewBuilder
    private var dueLine: some View {
        if let spoken = memo.spokenDueDate {
            Text(spoken)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(TMColor.accent)
        }
    }

    @ViewBuilder
    private var transcriptLine: some View {
        if let transcript {
            HStack(alignment: .top, spacing: TMSpace.xs + 2) {
                // Il glifo 🎤 non scala con Dynamic Type e non ha una label
                // VoiceOver utile: sostituito da quote.opening (2d).
                Image(systemName: "quote.opening")
                    .imageScale(.small)
                Text(transcript)
            }
            .font(.footnote)
            .foregroundStyle(.secondary)
        }
    }
}

// MARK: - 3g · Azioni

struct MemoActions {
    let addToCalendar: () -> Void
    let addToReminder: () -> Void
    let share: () -> Void
    let delete: () -> Void
}

extension View {
    /// Le stesse quattro azioni in tre forme: swipe, long-press e azioni
    /// personalizzate VoiceOver. Calendario e Promemoria spariscono quando il
    /// memo è già lì, così ne restano tre e lo swipe resta usabile.
    func memoActions(for memo: MemoItem, actions: MemoActions) -> some View {
        modifier(MemoActionsModifier(memo: memo, actions: actions))
    }
}

private struct MemoActionsModifier: ViewModifier {
    let memo: MemoItem
    let actions: MemoActions

    @State private var confirmingDelete = false

    func body(content: Content) -> some View {
        content
            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                if !memo.isInCalendar {
                    Button(action: actions.addToCalendar) {
                        Label("Calendario", systemImage: "calendar.badge.plus")
                    }
                    .tint(TMColor.calendar)
                }
                if !memo.isInReminder {
                    Button(action: actions.addToReminder) {
                        Label("Promemoria", systemImage: "checklist")
                    }
                    .tint(TMColor.reminder)
                }
                Button(action: actions.share) {
                    Label("Condividi", systemImage: "square.and.arrow.up")
                }
                .tint(TMColor.local)

                Button(role: .destructive, action: requestDelete) {
                    Label("Elimina", systemImage: "trash")
                }
            }
            .contextMenu {
                if !memo.isInCalendar {
                    Button(action: actions.addToCalendar) {
                        Label("Aggiungi al Calendario", systemImage: "calendar.badge.plus")
                    }
                }
                if !memo.isInReminder {
                    Button(action: actions.addToReminder) {
                        Label("Aggiungi a Promemoria", systemImage: "checklist")
                    }
                }
                Button(action: actions.share) {
                    Label("Condividi", systemImage: "square.and.arrow.up")
                }
                Button(role: .destructive, action: requestDelete) {
                    Label("Elimina", systemImage: "trash")
                }
            }
            .accessibilityActions {
                if !memo.isInCalendar {
                    Button("Aggiungi al Calendario", action: actions.addToCalendar)
                }
                if !memo.isInReminder {
                    Button("Aggiungi a Promemoria", action: actions.addToReminder)
                }
                Button("Condividi", action: actions.share)
                Button("Elimina", action: requestDelete)
            }
            .confirmationDialog("Eliminare il memo e il suo evento?",
                                isPresented: $confirmingDelete,
                                titleVisibility: .visible) {
                Button("Elimina", role: .destructive, action: actions.delete)
                Button("Mantieni", role: .cancel) {}
            } message: {
                Text("L'evento collegato verrà rimosso anche dal Calendario.")
            }
    }

    /// Elimina chiede conferma solo se il memo ha qualcosa da perdere fuori dall'app.
    private func requestDelete() {
        if memo.isInCalendar || memo.isInReminder {
            confirmingDelete = true
        } else {
            actions.delete()
        }
    }
}
