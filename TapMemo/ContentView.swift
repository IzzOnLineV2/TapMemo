//
//  ContentView.swift
//  TapMemo
//
//  Created by Stefania Izzo on 03/03/26.
//
//  Parte 3 del redesign — una sola schermata come prima, ma con il pulsante in
//  basso (raggiungibile con il pollice, in auto, con una mano) e la lista come
//  pila di card invece di List + Divider.
//

import SwiftUI
import SwiftData
import UIKit

struct ContentView: View {

    @Environment(\.modelContext) private var context
    @Environment(\.scenePhase) private var scenePhase

    @Query(sort: \MemoItem.createdAt, order: .reverse)
    private var memos: [MemoItem]

    @StateObject private var voice = VoiceManager()
    @StateObject private var service = MemoCreationService()

    /// Un solo canale per i guasti, da qualunque parte arrivino.
    private var activeIssue: AppIssue? { voice.issue ?? service.issue }

    var body: some View {
        ZStack {
            TMColor.canvas.ignoresSafeArea()

            VStack(spacing: 0) {
                if !isEmptyState { header }

                if let issue = activeIssue {
                    IssueCard(issue: issue, onDismiss: dismissIssue)
                        .padding(.horizontal, TMSpace.screenMargin)
                        .padding(.bottom, TMSpace.m)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }

                content

                RecordDock(isRecording: voice.isRecording,
                           isEnabled: !service.isProcessing,
                           invitesTap: showsInvitation,
                           action: handleRecordTap)
            }

            if voice.isRecording {
                RecordingOverlay(level: voice.level,
                                 partialText: voice.partialText,
                                 onFinish: voice.stopRecording,
                                 onCancel: voice.cancelRecording)
                    .transition(.opacity)
                    .zIndex(1)
            }
        }
        .animation(TMMotion.state, value: voice.isRecording)
        .animation(TMMotion.state, value: activeIssue)
        .sheet(item: $service.confirmation) { confirmation in
            ConfirmationSheet(
                confirmation: confirmation,
                onUndo: { Task { await service.undo(confirmation, context: context) } },
                onChangeTime: { date in Task { await service.changeTime(of: confirmation.memo, to: date) } },
                onAddToCalendar: {
                    Task {
                        await service.saveAsCalendarEvent(confirmation.memo,
                                                          date: confirmation.memo.dueAt ?? Self.defaultDate)
                        service.confirmation = nil
                    }
                },
                onDone: { service.confirmation = nil }
            )
        }
        .task {
            await voice.requestPermissions()
            await service.syncWithEventKit(memos: memos, context: context)
            consumePendingRecordRequest()
        }
        .onChange(of: scenePhase) { _, newPhase in
            guard newPhase == .active else { return }
            Task { await service.syncWithEventKit(memos: memos, context: context) }
            consumePendingRecordRequest()
        }
        .onOpenURL { url in
            if url.host == "record" { startRecording() }
        }
    }

    // MARK: - Pezzi

    private var header: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("TapMemo")
                .font(.largeTitle)
                .fontWeight(.bold)

            Group {
                if service.isProcessing {
                    Text("Sto capendo quando…")
                        .foregroundStyle(TMColor.accent)
                } else {
                    Text("\(memos.count) memo")
                        .foregroundStyle(.secondary)
                }
            }
            .font(.subheadline)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, TMSpace.screenMargin)
        .padding(.top, TMSpace.s)
        .padding(.bottom, TMSpace.l)
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private var content: some View {
        if isEmptyState {
            ScrollView { EmptyStateView() }
                .scrollBounceBehavior(.basedOnSize)
        } else {
            List {
                if let transcript = service.processingTranscript {
                    ProcessingCard(transcript: transcript)
                        .modifier(CardRow())
                }

                ForEach(memos) { memo in
                    MemoCard(memo: memo)
                        .modifier(CardRow())
                        .memoActions(for: memo, actions: actions(for: memo))
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .scrollDismissesKeyboard(.immediately)
        }
    }

    /// Primo avvio: la schermata è tutta per la promessa (3b), niente intestazione.
    private var isEmptyState: Bool {
        memos.isEmpty && !service.isProcessing
    }

    private var showsInvitation: Bool {
        isEmptyState && !voice.isRecording
    }

    // MARK: - Azioni

    private func actions(for memo: MemoItem) -> MemoActions {
        MemoActions(
            addToCalendar: {
                Task { await service.saveAsCalendarEvent(memo, date: memo.dueAt ?? Self.defaultDate) }
            },
            addToReminder: {
                Task { await service.saveAsReminder(memo) }
            },
            share: { share(memo) },
            delete: {
                Task { await service.deleteMemo(memo, context: context) }
            }
        )
    }

    private func handleRecordTap() {
        if voice.isRecording {
            voice.stopRecording()
        } else {
            startRecording()
        }
    }

    private func startRecording() {
        voice.startRecording { text in
            Task { await service.handleNewTranscript(text, context: context) }
        }
    }

    private func dismissIssue() {
        voice.issue = nil
        service.issue = nil
    }

    /// Il controllo di Control Center / Action Button lascia una richiesta nel
    /// gruppo condiviso: l'app la raccoglie appena torna in primo piano.
    private func consumePendingRecordRequest() {
        guard let defaults = UserDefaults(suiteName: TapMemoSharedStore.appGroupID),
              defaults.bool(forKey: TapMemoSharedStore.pendingRecordKey) else { return }

        defaults.set(false, forKey: TapMemoSharedStore.pendingRecordKey)
        startRecording()
    }

    private func share(_ memo: MemoItem) {
        let text = "\(memo.normalizedTitle)\n\n\(memo.originalText)"
        let controller = UIActivityViewController(activityItems: [text], applicationActivities: nil)

        controller.completionWithItemsHandler = { _, completed, _, _ in
            guard completed else { return }
            memo.isShared = true
            Haptics.success()
        }

        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let root = scene.windows.first(where: { $0.isKeyWindow })?.rootViewController else { return }
        root.present(controller, animated: true)
    }

    /// Un memo senza data messo in Calendario finisce domani alle 9:00.
    private static var defaultDate: Date {
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
        return Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: tomorrow) ?? tomorrow
    }
}

// MARK: - Riga senza cromature di List

/// Il List resta (serve per le swipe action), ma non si vede: niente separatori,
/// niente fondo di riga, margini dai token.
private struct CardRow: ViewModifier {
    func body(content: Content) -> some View {
        content
            .listRowSeparator(.hidden)
            .listRowBackground(Color.clear)
            .listRowInsets(EdgeInsets(top: TMSpace.rowGap / 2,
                                      leading: TMSpace.screenMargin,
                                      bottom: TMSpace.rowGap / 2,
                                      trailing: TMSpace.screenMargin))
    }
}

// MARK: - Preview

#Preview {
    ContentView()
        .modelContainer(for: [MemoItem.self], inMemory: true)
}
