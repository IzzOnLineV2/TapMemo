//
//  TapMemoWidget.swift
//  TapMemoWidget
//
//  Created by Stefania Izzo on 03/03/26.
//
//  Parte 4 del redesign — il widget non replica l'app: fa una cosa (far partire
//  la registrazione) e mostra il prossimo impegno.
//

import WidgetKit
import SwiftUI
import SwiftData

// MARK: - Timeline Provider

struct TapMemoWidgetProvider: TimelineProvider {

    func placeholder(in context: Context) -> TapMemoEntry {
        TapMemoEntry(date: Date(), memos: Self.sampleMemos)
    }

    func getSnapshot(in context: Context, completion: @escaping (TapMemoEntry) -> Void) {
        let memos = context.isPreview ? Self.sampleMemos : fetchMemos()
        completion(TapMemoEntry(date: Date(), memos: memos))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<TapMemoEntry>) -> Void) {
        let entry = TapMemoEntry(date: Date(), memos: fetchMemos())
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: Date()) ?? Date()
        completion(Timeline(entries: [entry], policy: .after(nextUpdate)))
    }

    /// Lettura in sola lettura dello store condiviso. Se l'app non è mai stata
    /// aperta il database non esiste ancora: il widget lo dice e basta.
    private func fetchMemos() -> [MemoSnapshot] {
        guard let storeURL = TapMemoSharedStore.storeURL,
              FileManager.default.fileExists(atPath: storeURL.path) else { return [] }

        let config = ModelConfiguration(url: storeURL)

        guard let container = try? ModelContainer(for: MemoItem.self, configurations: config) else {
            return []
        }

        let descriptor = FetchDescriptor<MemoItem>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )

        let context = ModelContext(container)
        guard let memos = try? context.fetch(descriptor) else { return [] }

        return memos.prefix(8).map(MemoSnapshot.init)
    }

    static let sampleMemos: [MemoSnapshot] = [
        MemoSnapshot(title: "Fare la spesa", dueAt: Date().addingTimeInterval(86_400),
                     spokenDueDate: "domani, 15:00", destination: .calendar),
        MemoSnapshot(title: "Prendere Pietro", dueAt: Date().addingTimeInterval(3_600),
                     spokenDueDate: "oggi, 17:00", destination: .reminder),
        MemoSnapshot(title: "Chiamare il dentista", dueAt: nil,
                     spokenDueDate: nil, destination: .local)
    ]
}

struct TapMemoEntry: TimelineEntry {
    let date: Date
    let memos: [MemoSnapshot]

    /// Il prossimo impegno davvero futuro; se non ce n'è, il memo più recente.
    var next: MemoSnapshot? {
        memos
            .filter { ($0.dueAt ?? .distantPast) >= date }
            .min { ($0.dueAt ?? .distantFuture) < ($1.dueAt ?? .distantFuture) }
            ?? memos.first
    }

    var todayCount: Int {
        memos.filter { guard let due = $0.dueAt else { return false }
                       return Calendar.current.isDateInToday(due) }.count
    }
}

// MARK: - Pezzi comuni

private let recordURL = URL(string: "tapmemo://record")!

/// Il disco resta pieno anche in tinted: una forma piena è l'unica che tiene il
/// contrasto quando il colore lo decide il sistema (5c).
private struct RecordDisc: View {
    var size: CGFloat = 64
    var label: LocalizedStringKey? = "Parla"

    var body: some View {
        VStack(spacing: TMSpace.s) {
            ZStack {
                Circle()
                    .fill(TMColor.accent)
                    .frame(width: size, height: size)

                Image(systemName: "mic.fill")
                    .font(.system(size: size * 0.42, weight: .medium))
                    .foregroundStyle(.white)
            }
            .widgetAccentable()

            if let label {
                Text(label)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Registra un memo")
        .accessibilityAddTraits(.isButton)
    }
}

/// Riga del widget: titolo + data e destinazione, il badge ridotto a un punto
/// solo dove non c'è spazio per la parola.
private struct WidgetMemoRow: View {
    let memo: MemoSnapshot
    var showsDestination = true

    @Environment(\.widgetRenderingMode) private var renderingMode

    var body: some View {
        HStack(alignment: .top, spacing: TMSpace.s) {
            if renderingMode == .fullColor {
                MemoStatusDot(destination: memo.destination)
                    .padding(.top, 5)
            }

            VStack(alignment: .leading, spacing: 1) {
                Text(memo.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)

                if let detail = detailText {
                    Text(detail)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer(minLength: 0)
        }
        .accessibilityElement(children: .combine)
    }

    private var detailText: String? {
        let destination: String? = showsDestination ? memo.destination.plainLabel : nil

        guard let date = memo.spokenDueDate else { return destination }
        guard let destination else { return date }
        return "\(date) · \(destination)"
    }
}

// MARK: - Home Screen (5a)

struct TapMemoWidgetEntryView: View {
    var entry: TapMemoEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .systemSmall:        SmallWidgetView(entry: entry)
        case .systemMedium:       MediumWidgetView(entry: entry)
        case .systemLarge:        LargeWidgetView(entry: entry)
        case .accessoryCircular:  CircularAccessoryView(entry: entry)
        case .accessoryRectangular: RectangularAccessoryView(entry: entry)
        case .accessoryInline:    InlineAccessoryView(entry: entry)
        default:                  SmallWidgetView(entry: entry)
        }
    }
}

struct SmallWidgetView: View {
    let entry: TapMemoEntry

    var body: some View {
        Link(destination: recordURL) {
            RecordDisc(size: 64)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .containerBackground(TMColor.card, for: .widget)
    }
}

struct MediumWidgetView: View {
    let entry: TapMemoEntry

    var body: some View {
        HStack(spacing: TMSpace.l) {
            Link(destination: recordURL) {
                RecordDisc(size: 56)
                    .frame(maxWidth: 88, maxHeight: .infinity)
            }

            VStack(alignment: .leading, spacing: TMSpace.s) {
                Text("Prossimi")
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)

                if entry.memos.isEmpty {
                    Text("Nessun memo")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(maxHeight: .infinity, alignment: .center)
                } else {
                    ForEach(sortedMemos.prefix(2)) { memo in
                        WidgetMemoRow(memo: memo, showsDestination: false)
                    }
                    Spacer(minLength: 0)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .containerBackground(TMColor.card, for: .widget)
    }

    /// In tinted il colore di stato non c'è: la destinazione si legge dall'ordine.
    private var sortedMemos: [MemoSnapshot] {
        entry.memos.sorted { lhs, rhs in
            if lhs.destinationRank != rhs.destinationRank { return lhs.destinationRank < rhs.destinationRank }
            return (lhs.dueAt ?? .distantFuture) < (rhs.dueAt ?? .distantFuture)
        }
    }
}

struct LargeWidgetView: View {
    let entry: TapMemoEntry

    var body: some View {
        VStack(alignment: .leading, spacing: TMSpace.m) {
            HStack {
                Text("TapMemo")
                    .font(.headline)

                Spacer()

                Link(destination: recordURL) {
                    RecordDisc(size: 40, label: nil)
                }
            }

            if entry.memos.isEmpty {
                VStack(spacing: TMSpace.s) {
                    Image(systemName: "waveform")
                        .font(.system(size: 36))
                        .foregroundStyle(.tertiary)
                    Text("Nessun memo ancora")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                VStack(alignment: .leading, spacing: TMSpace.m) {
                    ForEach(entry.memos.prefix(4)) { memo in
                        WidgetMemoRow(memo: memo)
                    }
                }

                Spacer(minLength: 0)

                Text("Tocca il cerchio per registrare")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
        }
        .containerBackground(TMColor.card, for: .widget)
    }
}

// MARK: - Lock Screen (5b)

/// Le tre famiglie sono monocromatiche per forza: lo stato passa dal peso del
/// testo, non dal colore.
struct CircularAccessoryView: View {
    let entry: TapMemoEntry

    var body: some View {
        ZStack {
            AccessoryWidgetBackground()
            VStack(spacing: 0) {
                Image(systemName: "mic.fill")
                    .font(.system(size: 14, weight: .semibold))
                Text("\(entry.todayCount)")
                    .font(.system(size: 13, weight: .bold))
            }
        }
        .widgetLabel("oggi")
        .accessibilityLabel("TapMemo, \(entry.todayCount) memo oggi")
    }
}

struct RectangularAccessoryView: View {
    let entry: TapMemoEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 1) {
            Text("TapMemo · tocca e parla")
                .font(.caption2)
                .textCase(.uppercase)

            if let next = entry.next {
                Text(next.title)
                    .font(.headline)
                    .lineLimit(1)

                if let detail = next.spokenDueDate {
                    Text("\(detail) · \(next.destination.plainLabel)")
                        .font(.caption2)
                        .lineLimit(1)
                }
            } else {
                Text("Nessun memo")
                    .font(.headline)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct InlineAccessoryView: View {
    let entry: TapMemoEntry

    var body: some View {
        if let next = entry.next, let detail = next.spokenDueDate {
            Text("\(next.title) · \(detail)")
        } else {
            Text("TapMemo · tocca e parla")
        }
    }
}

// MARK: - Configurazione

struct TapMemoWidget: Widget {
    let kind: String = "TapMemoWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: TapMemoWidgetProvider()) { entry in
            TapMemoWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("TapMemo")
        .description("Registra un memo con un tocco e vedi il prossimo impegno.")
        .supportedFamilies([
            .systemSmall, .systemMedium, .systemLarge,
            .accessoryCircular, .accessoryRectangular, .accessoryInline
        ])
    }
}

// MARK: - Previews

#Preview(as: .systemSmall) {
    TapMemoWidget()
} timeline: {
    TapMemoEntry(date: .now, memos: TapMemoWidgetProvider.sampleMemos)
}

#Preview(as: .systemMedium) {
    TapMemoWidget()
} timeline: {
    TapMemoEntry(date: .now, memos: TapMemoWidgetProvider.sampleMemos)
}

#Preview(as: .systemLarge) {
    TapMemoWidget()
} timeline: {
    TapMemoEntry(date: .now, memos: TapMemoWidgetProvider.sampleMemos)
}

#Preview(as: .accessoryRectangular) {
    TapMemoWidget()
} timeline: {
    TapMemoEntry(date: .now, memos: TapMemoWidgetProvider.sampleMemos)
}
