//
//  MemoPresentation.swift
//  TapMemo
//
//  Parte 3 · 3f — lo stato di un memo è detto UNA VOLTA SOLA: un badge, in
//  italiano, col colore del token di destinazione. Prima era detto tre volte e
//  in due lingue (badge "EVENT" + riga "In Calendario" + pallino nel widget).
//  Condiviso con l'estensione widget, dove il badge si riduce a un punto.
//

import SwiftUI

// MARK: - Destinazione

enum MemoDestination {
    case calendar
    case reminder
    case local

    var label: LocalizedStringKey {
        switch self {
        case .calendar: "In Calendario"
        case .reminder: "In Promemoria"
        case .local:    "Solo in TapMemo"
        }
    }

    /// Testo non localizzabile-in-vista, per VoiceOver e per il widget inline.
    var plainLabel: String {
        switch self {
        case .calendar: String(localized: "In Calendario")
        case .reminder: String(localized: "In Promemoria")
        case .local:    String(localized: "Solo in TapMemo")
        }
    }

    var color: Color {
        switch self {
        case .calendar: TMColor.calendar
        case .reminder: TMColor.reminder
        case .local:    TMColor.local
        }
    }

    var symbol: String {
        switch self {
        case .calendar: "calendar"
        case .reminder: "checklist"
        case .local:    "tray"
        }
    }

    /// Ordine usato in tinted mode, dove il colore non è disponibile e la
    /// destinazione si legge dalla posizione (5c).
    /// `nonisolated`: il widget lo legge dalla sua timeline, fuori dal main actor.
    nonisolated var sortRank: Int {
        switch self {
        case .calendar: 0
        case .reminder: 1
        case .local:    2
        }
    }
}

extension MemoItem {
    /// La destinazione principale. Un memo in entrambi i posti è «in Calendario»
    /// con un'aggiunta, perché l'evento è l'esito che l'app promette.
    nonisolated var destination: MemoDestination {
        if isInCalendar { return .calendar }
        if isInReminder { return .reminder }
        return .local
    }

    /// Vero quando il badge deve portare anche «+ Promemoria».
    var hasSecondaryDestination: Bool { isInCalendar && isInReminder }

    /// Data in forma parlata: «domani, 15:00». Nil se il memo non ha data.
    nonisolated var spokenDueDate: String? {
        guard let dueAt else { return nil }
        let cal = Calendar.current
        let time = dueAt.formatted(date: .omitted, time: .shortened)

        if cal.isDateInToday(dueAt) { return String(localized: "oggi, \(time)") }
        if cal.isDateInTomorrow(dueAt) { return String(localized: "domani, \(time)") }

        let day = dueAt.formatted(.dateTime.weekday(.wide).day().locale(.current))
        return "\(day) · \(time)"
    }

    /// Un solo elemento accessibile per card: «Fare la spesa, domani alle 15, in Calendario».
    var accessibilityDescription: String {
        var parts = [normalizedTitle]
        if let spokenDueDate { parts.append(spokenDueDate) }
        parts.append(destination.plainLabel)
        if hasSecondaryDestination { parts.append(String(localized: "In Promemoria")) }
        return parts.joined(separator: ", ")
    }
}

// MARK: - Badge

/// Il badge non è solo colore: porta sempre la parola (3f).
struct MemoStatusBadge: View {
    let destination: MemoDestination
    var secondary: Bool = false
    var compact: Bool = false

    var body: some View {
        HStack(spacing: TMSpace.xs) {
            Text(destination.label)
            if secondary {
                Text("+ Promemoria")
                    .foregroundStyle(TMColor.reminder)
            }
        }
        .font(.caption)
        .fontWeight(.semibold)
        .foregroundStyle(destination.color)
        .padding(.horizontal, compact ? TMSpace.s : TMSpace.m)
        .padding(.vertical, compact ? 3 : TMSpace.xs + 2)
        .background(
            RoundedRectangle(cornerRadius: TMRadius.badge, style: .continuous)
                .fill(destination.color.opacity(0.12))
        )
        .accessibilityHidden(true)
    }
}

/// Il badge in miniatura: un punto, usato solo dove non c'è spazio per la parola.
struct MemoStatusDot: View {
    let destination: MemoDestination
    var size: CGFloat = 8

    var body: some View {
        Circle()
            .fill(destination.color)
            .frame(width: size, height: size)
            .accessibilityHidden(true)
    }
}

// MARK: - Snapshot per il widget

/// Copia inerte di un memo. Il widget non deve tenere in vita oggetti SwiftData
/// legati a un contesto che, nella sua timeline, non esiste più.
struct MemoSnapshot: Identifiable, Hashable {
    let id: UUID
    let title: String
    let dueAt: Date?
    let spokenDueDate: String?
    let destinationRank: Int
    private let destinationRaw: Int

    var destination: MemoDestination {
        switch destinationRaw {
        case 0: .calendar
        case 1: .reminder
        default: .local
        }
    }

    /// Il widget costruisce gli snapshot nella sua timeline, fuori dal main actor.
    nonisolated init(_ memo: MemoItem) {
        id = memo.id
        title = memo.normalizedTitle
        dueAt = memo.dueAt
        spokenDueDate = memo.spokenDueDate
        destinationRaw = memo.destination.sortRank
        destinationRank = memo.destination.sortRank
    }

    /// Solo per le anteprime e il placeholder del widget.
    init(id: UUID = UUID(), title: String, dueAt: Date?, spokenDueDate: String?, destination: MemoDestination) {
        self.id = id
        self.title = title
        self.dueAt = dueAt
        self.spokenDueDate = spokenDueDate
        self.destinationRaw = destination.sortRank
        self.destinationRank = destination.sortRank
    }
}
