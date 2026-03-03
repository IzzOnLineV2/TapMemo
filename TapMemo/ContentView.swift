//
//  ContentView.swift
//  TapMemo
//
//  Created by Stefania Izzo on 03/03/26.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    
    @Environment(\.modelContext) private var context
    @Query(sort: \MemoItem.createdAt, order: .reverse)
    private var memos: [MemoItem]
    
    @StateObject private var voiceManager = VoiceManager()
    @StateObject private var memoService = MemoCreationService()
    
    @State private var successMessage: String?
    @State private var showSuccessBanner = false
    @Environment(\.scenePhase) private var scenePhase
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                
                // Recording Button
                VStack(spacing: 12) {
                    Button(action: handleRecordTap) {
                        ZStack {
                            Circle()
                                .fill(voiceManager.isRecording ? Color.red : Color.blue)
                                .frame(width: 100, height: 100)
                                .shadow(color: voiceManager.isRecording ? .red.opacity(0.4) : .blue.opacity(0.3), 
                                       radius: voiceManager.isRecording ? 20 : 10)
                                .scaleEffect(voiceManager.isRecording ? 1.1 : 1.0)
                                .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), 
                                          value: voiceManager.isRecording)
                            
                            Image(systemName: voiceManager.isRecording ? "stop.fill" : "mic.fill")
                                .font(.largeTitle)
                                .foregroundColor(.white)
                        }
                    }
                    .buttonStyle(.plain)
                    
                    Text(voiceManager.isRecording ? "Sto ascoltando..." : "Tap per registrare")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    if memoService.isProcessing {
                        ProgressView()
                            .padding(.top, 4)
                    }
                }
                .padding(.vertical, 24)
                
                Divider()
                
                // Memo List
                List {
                    ForEach(memos) { memo in
                        MemoRow(memo: memo)
                            .swipeActions(edge: .trailing) {
                                
                                // Mostra azioni in base alla destinazione corrente
                                
                                // Calendario - solo se non è già in Calendario
                                if !memo.isInCalendar {
                                    Button {
                                        Task {
                                            await saveToCalendar(memo)
                                        }
                                    } label: {
                                        Label("Calendario", systemImage: "calendar.badge.plus")
                                    }
                                    .tint(.blue)
                                }
                                
                                // Promemoria - solo se non è già in Promemoria
                                if !memo.isInReminder {
                                    Button {
                                        Task {
                                            await memoService.saveAsReminder(memo)
                                            if memoService.lastError == nil {
                                                showFeedback("✅ Aggiunto a Promemoria")
                                            }
                                        }
                                    } label: {
                                        Label("Promemoria", systemImage: "checkmark.circle")
                                    }
                                    .tint(.orange)
                                }
                                
                                // Condividi - sempre disponibile
                                Button {
                                    shareMemo(memo)
                                } label: {
                                    Label("Condividi", systemImage: "square.and.arrow.up")
                                }
                                .tint(.purple)
                                
                                // Elimina - sempre disponibile
                                Button(role: .destructive) {
                                    Task {
                                        await memoService.deleteMemo(memo, context: context)
                                    }
                                } label: {
                                    Label("Elimina", systemImage: "trash")
                                }
                            }
                    }
                    .onDelete(perform: deleteMemos)
                }
                .listStyle(.plain)
            }
            .navigationTitle("TapMemo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                EditButton()
            }
        }
        .onAppear {
            voiceManager.requestPermissions()
            Task {
                await memoService.syncWithEventKit(memos: memos, context: context)
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                Task {
                    await memoService.syncWithEventKit(memos: memos, context: context)
                }
            }
        }
        .onOpenURL { url in
            if url.host == "record" {
                startRecording()
            }
        }
        .overlay(alignment: .top) {
            if showSuccessBanner, let message = successMessage {
                SuccessBanner(message: message)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .zIndex(1)
            }
        }
        .alert("Errore", isPresented: Binding(
            get: { memoService.lastError != nil },
            set: { if !$0 { memoService.lastError = nil } }
        )) {
            Button("OK") { memoService.lastError = nil }
        } message: {
            if let error = memoService.lastError {
                Text(error)
            }
        }
    }
    
    // MARK: - Actions
    
    private func handleRecordTap() {
        Haptics.tap()
        
        if voiceManager.isRecording {
            voiceManager.stopRecording()
        } else {
            startRecording()
        }
    }
    
    private func startRecording() {
        do {
            try voiceManager.startRecording { text in
                Haptics.success()
                Task {
                    await memoService.handleNewTranscript(text, context: context)
                }
            }
        } catch {
            Haptics.error()
            print("❌ Recording error: \(error)")
        }
    }
    
    private func saveToCalendar(_ memo: MemoItem) async {
        // Se non ha una data, usa domani alle 9:00 come default
        let dueDate = memo.dueAt ?? Calendar.current.date(byAdding: .day, value: 1, to: Date())!
        
        await memoService.saveAsCalendarEvent(memo, date: dueDate)
        
        if memoService.lastError == nil {
            showFeedback("✅ Aggiunto al Calendario")
        }
    }
    
    private func deleteMemos(at offsets: IndexSet) {
        for index in offsets {
            let memo = memos[index]
            Task {
                await memoService.deleteMemo(memo, context: context)
            }
        }
    }

    private func shareMemo(_ memo: MemoItem) {
        let text = "\(memo.normalizedTitle)\n\n🎤 \(memo.originalText)"
        let av = UIActivityViewController(
            activityItems: [text],
            applicationActivities: nil
        )
        
        av.completionWithItemsHandler = { _, completed, _, _ in
            if completed {
                memo.isShared = true
                Haptics.success()
                showFeedback("✅ Condiviso")
            }
        }
        
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let root = scene.windows.first?.rootViewController {
            root.present(av, animated: true)
        }
    }
    
    private func showFeedback(_ message: String) {
        successMessage = message
        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
            showSuccessBanner = true
        }
        
        Task {
            try? await Task.sleep(for: .seconds(2.5))
            withAnimation {
                showSuccessBanner = false
            }
            try? await Task.sleep(for: .seconds(0.3))
            successMessage = nil
        }
    }
}

// MARK: - Memo Row

struct MemoRow: View {
    let memo: MemoItem

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(memo.normalizedTitle)
                    .font(.headline)

                Spacer()

                // Badges
                HStack(spacing: 4) {
                    if memo.isInCalendar {
                        BadgeLabel("EVENT", color: .blue)
                    }
                    if memo.isInReminder {
                        BadgeLabel("REMINDER", color: .orange)
                    }
                    if memo.isLocal {
                        BadgeLabel("NOTE", color: .gray)
                    }
                }
            }

            // Due date
            if let dueAt = memo.dueAt {
                HStack(spacing: 4) {
                    Image(systemName: "clock")
                        .font(.caption)
                    Text(dueAt.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption)
                }
                .foregroundColor(.secondary)
            }

            // EventKit status
            VStack(alignment: .leading, spacing: 2) {
                if memo.isInCalendar {
                    StatusLabel(icon: "checkmark.circle.fill", text: "In Calendario", color: .green)
                }
                if memo.isInReminder {
                    StatusLabel(icon: "checkmark.circle.fill", text: "In Promemoria", color: .green)
                }
                if memo.isLocal {
                    StatusLabel(icon: "circle", text: "Solo in TapMemo", color: .secondary)
                }
            }

            // Original transcription (subtle)
            if memo.originalText != memo.normalizedTitle.lowercased() {
                Text("🎤 \"\(memo.originalText)\"")
                    .font(.caption2)
                    .foregroundColor(.secondary.opacity(0.7))
                    .italic()
                    .padding(.top, 4)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Helper Views

private struct BadgeLabel: View {
    let text: String
    let color: Color

    init(_ text: String, color: Color) {
        self.text = text
        self.color = color
    }

    var body: some View {
        Text(text)
            .font(.caption2)
            .fontWeight(.semibold)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.2))
            .foregroundColor(color)
            .cornerRadius(6)
    }
}

private struct StatusLabel: View {
    let icon: String
    let text: String
    let color: Color

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(color)
            Text(text)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Success Banner

struct SuccessBanner: View {
    let message: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .font(.title3)
                .foregroundColor(.green)
            
            Text(message)
                .font(.subheadline)
                .fontWeight(.medium)
            
            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.1), radius: 8, y: 4)
        )
        .padding(.horizontal)
        .padding(.top, 8)
    }
}

// MARK: - Preview

#Preview {
    ContentView()
        .modelContainer(for: [MemoItem.self], inMemory: true)
}
