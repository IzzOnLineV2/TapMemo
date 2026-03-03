//
//  TapMemoWidget.swift
//  TapMemoWidget
//
//  Created by Stefania Izzo on 03/03/26.
//

import WidgetKit
import SwiftUI
import SwiftData

// MARK: - Timeline Provider

struct TapMemoWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> TapMemoEntry {
        TapMemoEntry(date: Date(), memos: sampleMemos())
    }
    
    func getSnapshot(in context: Context, completion: @escaping (TapMemoEntry) -> Void) {
        let entry: TapMemoEntry
        
        if context.isPreview {
            entry = TapMemoEntry(date: Date(), memos: sampleMemos())
        } else {
            entry = TapMemoEntry(date: Date(), memos: fetchMemos())
        }
        
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<TapMemoEntry>) -> Void) {
        let memos = fetchMemos()
        let entry = TapMemoEntry(date: Date(), memos: memos)
        
        // Aggiorna ogni 15 minuti
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: Date())!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        
        completion(timeline)
    }
    
    private func fetchMemos() -> [MemoItem] {
        let appGroupID = "group.com.smartapibox.tapmemo"
        
        // Usa lo stesso App Group del main app
        guard let groupURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: appGroupID
        ) else {
            print("⚠️ Widget: App Group '\(appGroupID)' non trovato!")
            return []
        }
        
        let storeURL = groupURL.appendingPathComponent("TapMemo.sqlite")
        let config = ModelConfiguration(url: storeURL)
        
        guard let container = try? ModelContainer(for: MemoItem.self, configurations: config) else {
            print("⚠️ Widget: Failed to create ModelContainer")
            return []
        }
        
        let descriptor = FetchDescriptor<MemoItem>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        
        // Usa ModelContext in modo sicuro
        let fetchResult: [MemoItem]? = {
            let context = ModelContext(container)
            return try? context.fetch(descriptor)
        }()
        
        guard let memos = fetchResult else {
            print("⚠️ Widget: Failed to fetch memos")
            return []
        }
        
        print("✅ Widget: Caricati \(memos.count) memo dal database condiviso")
        return Array(memos.prefix(5))
    }
    
    private func sampleMemos() -> [MemoItem] {
        [
            MemoItem(
                originalText: "prendere pietro alle 3",
                normalizedTitle: "Prendere Pietro",
                dueAt: Date().addingTimeInterval(3600)
            ),
            MemoItem(
                originalText: "fare la spesa domani",
                normalizedTitle: "Fare la spesa",
                dueAt: Date().addingTimeInterval(86400)
            )
        ]
    }
}

// MARK: - Timeline Entry

struct TapMemoEntry: TimelineEntry {
    let date: Date
    let memos: [MemoItem]
}

// MARK: - Widget Views

struct TapMemoWidgetEntryView: View {
    var entry: TapMemoEntry
    @Environment(\.widgetFamily) var family
    
    var body: some View {
        switch family {
        case .systemSmall:
            SmallWidgetView(memos: entry.memos)
        case .systemMedium:
            MediumWidgetView(memos: entry.memos)
        case .systemLarge:
            LargeWidgetView(memos: entry.memos)
        default:
            SmallWidgetView(memos: entry.memos)
        }
    }
}

// MARK: - Small Widget

struct SmallWidgetView: View {
    let memos: [MemoItem]

    var body: some View {
        Link(destination: URL(string: "tapmemo://record")!) {
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color.blue.gradient)
                        .frame(width: 64, height: 64)

                    Image(systemName: "mic.fill")
                        .font(.system(size: 28))
                        .foregroundColor(.white)
                }

                Text("Registra")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

// MARK: - Medium Widget

struct MediumWidgetView: View {
    let memos: [MemoItem]
    
    var body: some View {
        HStack(spacing: 12) {
            // Quick Action
            Link(destination: URL(string: "tapmemo://record")!) {
                VStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .fill(Color.blue.gradient)
                            .frame(width: 56, height: 56)

                        Image(systemName: "mic.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.white)
                    }

                    Text("Registra")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                }
                .frame(maxWidth: 80, maxHeight: .infinity)
            }
            
            // Memo recenti
            VStack(alignment: .leading, spacing: 8) {
                Text("Recenti")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)
                
                if memos.isEmpty {
                    Text("Nessun memo")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(maxHeight: .infinity)
                } else {
                    ForEach(memos.prefix(3)) { memo in
                        HStack(spacing: 6) {
                            Circle()
                                .fill(memoColor(memo))
                                .frame(width: 6, height: 6)
                            
                            Text(memo.normalizedTitle)
                                .font(.caption)
                                .lineLimit(1)
                        }
                    }
                }
                
                Spacer()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .containerBackground(.fill.tertiary, for: .widget)
    }
    
    private func memoColor(_ memo: MemoItem) -> Color {
        if memo.isInCalendar { return .blue }
        if memo.isInReminder { return .orange }
        return .gray
    }
}

// MARK: - Large Widget

struct LargeWidgetView: View {
    let memos: [MemoItem]
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("TapMemo")
                    .font(.headline)
                
                Spacer()
                
                Link(destination: URL(string: "tapmemo://record")!) {
                    ZStack {
                        Circle()
                            .fill(Color.blue.gradient)
                            .frame(width: 36, height: 36)

                        Image(systemName: "mic.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.white)
                    }
                }
            }
            .padding()
            
            Divider()
            
            // Memo list
            if memos.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "mic.slash")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary.opacity(0.5))
                    
                    Text("Nessun memo ancora")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxHeight: .infinity)
            } else {
                VStack(spacing: 8) {
                    ForEach(Array(memos.prefix(5))) { memo in
                        WidgetMemoRow(memo: memo)
                    }
                    Spacer()
                }
                .padding()
            }
        }
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

struct WidgetMemoRow: View {
    let memo: MemoItem
    
    var body: some View {
        HStack(spacing: 12) {
            // Icon
            Circle()
                .fill(memoColor(memo))
                .frame(width: 10, height: 10)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(memo.normalizedTitle)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)
                
                if let dueAt = memo.dueAt {
                    Text(dueAt.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Badge
            Image(systemName: memoIcon(memo))
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
    
    private func memoColor(_ memo: MemoItem) -> Color {
        if memo.isInCalendar { return .blue }
        if memo.isInReminder { return .orange }
        return .gray
    }

    private func memoIcon(_ memo: MemoItem) -> String {
        if memo.isInCalendar { return "calendar" }
        if memo.isInReminder { return "checkmark.circle" }
        return "tray"
    }
}

// MARK: - Widget Configuration

struct TapMemoWidget: Widget {
    let kind: String = "TapMemoWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: TapMemoWidgetProvider()) { entry in
            TapMemoWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("TapMemo")
        .description("Visualizza i tuoi memo recenti e registra rapidamente nuovi promemoria vocali.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

// MARK: - Previews

#Preview(as: .systemSmall) {
    TapMemoWidget()
} timeline: {
    TapMemoEntry(date: .now, memos: [
        MemoItem(originalText: "test", normalizedTitle: "Prendere Pietro", dueAt: Date())
    ])
}

#Preview(as: .systemMedium) {
    TapMemoWidget()
} timeline: {
    TapMemoEntry(date: .now, memos: [
        MemoItem(originalText: "test", normalizedTitle: "Prendere Pietro", dueAt: Date()),
        MemoItem(originalText: "test", normalizedTitle: "Fare la spesa", dueAt: Date())
    ])
}

#Preview(as: .systemLarge) {
    TapMemoWidget()
} timeline: {
    TapMemoEntry(date: .now, memos: [
        MemoItem(originalText: "test", normalizedTitle: "Prendere Pietro", dueAt: Date()),
        MemoItem(originalText: "test", normalizedTitle: "Fare la spesa", dueAt: Date()),
        MemoItem(originalText: "test", normalizedTitle: "Dentista", dueAt: Date())
    ])
}
