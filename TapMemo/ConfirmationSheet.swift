//
//  ConfirmationSheet.swift
//  TapMemo
//
//  Parte 3 · 3e — sostituisce il banner verde generico: dice COSA è stato creato
//  e QUANDO, e «Annulla» elimina davvero l'evento appena creato.
//

import SwiftUI
import UIKit

struct ConfirmationSheet: View {
    let confirmation: MemoConfirmation
    let onUndo: () -> Void
    let onChangeTime: (Date) -> Void
    let onAddToCalendar: () -> Void
    let onDone: () -> Void

    @State private var remaining = 4
    @State private var countdownRunning = true
    @State private var isPickingTime = false
    @State private var pickedDate = Date()

    private var memo: MemoItem { confirmation.memo }
    private var createdEvent: Bool { confirmation.outcome == .eventCreated }

    var body: some View {
        VStack(alignment: .leading, spacing: TMSpace.l) {
            header

            VStack(alignment: .leading, spacing: TMSpace.xs) {
                Text(memo.normalizedTitle)
                    .font(.title2)
                    .fontWeight(.semibold)

                if let detail = dateDetail {
                    // Forma parlata + assoluta, così «alle 3 → 15:00» è verificabile.
                    Text(detail)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(TMColor.accent)
                } else {
                    Text(AppIssue.noDateHint)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                if memo.originalText.lowercased() != memo.normalizedTitle.lowercased() {
                    Text("«\(memo.originalText)»")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .padding(.top, TMSpace.xs)
                }
            }

            if isPickingTime {
                DatePicker("Nuova ora",
                           selection: $pickedDate,
                           displayedComponents: [.date, .hourAndMinute])
                    .datePickerStyle(.compact)
                    .labelsHidden()
                    .onChange(of: pickedDate) { _, newValue in
                        onChangeTime(newValue)
                    }
            }

            Spacer(minLength: 0)

            actions

            if countdownRunning {
                Text("Si chiude da sé fra \(remaining) s")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .accessibilityHidden(true)
            }
        }
        .padding(TMSpace.xl)
        .frame(maxWidth: .infinity, alignment: .leading)
        .presentationDetents([.height(340), .large])
        .presentationCornerRadius(TMRadius.sheet)
        .presentationDragIndicator(.visible)
        // Qualunque tocco sul foglio sospende la chiusura automatica.
        .simultaneousGesture(DragGesture(minimumDistance: 0).onChanged { _ in
            countdownRunning = false
        })
        .task { await runCountdown() }
        .onAppear { pickedDate = memo.dueAt ?? defaultSuggestedDate }
    }

    // MARK: - Pezzi

    private var header: some View {
        Label {
            Text(createdEvent ? "Evento creato in Calendario" : "Memo salvato in TapMemo")
                .font(.headline)
        } icon: {
            // La spunta verde resta solo nell'istante della conferma.
            Image(systemName: createdEvent ? "checkmark.circle.fill" : "tray.fill")
                .foregroundStyle(createdEvent ? TMColor.success : TMColor.local)
        }
    }

    private var actions: some View {
        HStack(spacing: TMSpace.m) {
            if createdEvent {
                Button("Cambia ora") {
                    countdownRunning = false
                    withAnimation(TMMotion.reveal) { isPickingTime = true }
                }
                .buttonStyle(.bordered)

                Button("Annulla", role: .destructive, action: onUndo)
                    .buttonStyle(.bordered)
            } else {
                Button("Metti in Calendario", action: onAddToCalendar)
                    .buttonStyle(.bordered)
                    .tint(TMColor.calendar)
            }

            Spacer(minLength: 0)

            Button("Fatto", action: onDone)
                .buttonStyle(.borderedProminent)
                .tint(TMColor.accent)
        }
        .font(.subheadline)
    }

    // MARK: - Dati

    /// «domani, martedì 22 · 15:00»
    private var dateDetail: String? {
        guard let due = memo.dueAt else { return nil }

        let calendar = Calendar.current
        let time = due.formatted(date: .omitted, time: .shortened)
        let absolute = due.formatted(.dateTime.weekday(.wide).day())

        if calendar.isDateInToday(due) { return String(localized: "oggi, \(absolute) · \(time)") }
        if calendar.isDateInTomorrow(due) { return String(localized: "domani, \(absolute) · \(time)") }
        return "\(absolute) · \(time)"
    }

    private var defaultSuggestedDate: Date {
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
        return Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: tomorrow) ?? tomorrow
    }

    /// La finestra di 4 s è sospesa con VoiceOver attivo: lì il tempo lo decide
    /// chi legge, non un timer.
    private func runCountdown() async {
        if UIAccessibility.isVoiceOverRunning {
            countdownRunning = false
            return
        }

        while remaining > 0 {
            try? await Task.sleep(for: .seconds(1))
            guard !Task.isCancelled else { return }
            guard countdownRunning else { return }
            remaining -= 1
        }

        if countdownRunning { onDone() }
    }
}

extension AppIssue {
    /// La stessa copy di 3h per il memo senza data, qui usata come suggerimento
    /// invece che come errore: un memo senza data è un memo valido.
    static let noDateHint = String(localized: "Non ho sentito una data. Il memo è salvato: scorri per metterlo in Calendario.")
}
