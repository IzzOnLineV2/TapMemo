//
//  MemoCreationService.swift
//  TapMemo
//
//  Created by Stefania Izzo on 03/03/26.
//

import Foundation
import SwiftData
import Combine
import WidgetKit

@MainActor
final class MemoCreationService: ObservableObject {
    private let eventKit = EventKitService()
    
    @Published var lastError: String?
    @Published var isProcessing = false
    
    func handleNewTranscript(_ text: String, context: ModelContext) async {
        isProcessing = true
        lastError = nil
        
        // 1) Parse il testo
        let parsed = MemoParser.parse(text)
        
        // 2) Crea MemoItem
        let memo = MemoItem(
            originalText: text,
            normalizedTitle: parsed.title,
            dueAt: parsed.dueAt
        )
        
        // 3) Salva sempre in app
        context.insert(memo)
        
        // 4) REGOLA FINALE: Se ha data/ora → Calendario automatico
        if let due = parsed.dueAt {
            do {
                let isAllDay = Calendar.current.isDate(due,
                                                       equalTo: Calendar.current.startOfDay(for: due),
                                                       toGranularity: .minute)
                
                let id = try await eventKit.createCalendarEvent(
                    title: parsed.title,
                    date: due,
                    isAllDay: isAllDay
                )
                
                memo.calendarIdentifier = id

                Haptics.success()
                
            } catch {
                lastError = error.localizedDescription
                Haptics.error()
                print("⚠️ EventKit error: \(error)")
            }
        } else {
            // Senza data → resta local
            Haptics.success()
        }
        
        // Notifica il widget che i dati sono cambiati
        WidgetCenter.shared.reloadAllTimelines()
        print("🔄 Widget notificato per aggiornamento")
        
        isProcessing = false
    }
    
    func saveAsReminder(_ memo: MemoItem) async {
        do {
            let id = try await eventKit.createReminder(title: memo.normalizedTitle, due: memo.dueAt)
            memo.reminderIdentifier = id
            Haptics.success()
            
            // Notifica widget
            WidgetCenter.shared.reloadAllTimelines()
        } catch {
            lastError = error.localizedDescription
            Haptics.error()
        }
    }
    
    func saveAsCalendarEvent(_ memo: MemoItem, date: Date) async {
        do {
            let isAllDay = Calendar.current.isDate(date,
                                                   equalTo: Calendar.current.startOfDay(for: date),
                                                   toGranularity: .minute)
            
            let id = try await eventKit.createCalendarEvent(
                title: memo.normalizedTitle,
                date: date,
                isAllDay: isAllDay
            )
            
            memo.calendarIdentifier = id
            memo.dueAt = date
            Haptics.success()
            
            // Notifica widget
            WidgetCenter.shared.reloadAllTimelines()
            
        } catch {
            lastError = error.localizedDescription
            Haptics.error()
            print("⚠️ EventKit Calendar error: \(error)")
        }
    }
    
    func deleteMemo(_ item: MemoItem, context: ModelContext) async {
        // Elimina da EventKit se presente
        if let calId = item.calendarIdentifier {
            do {
                try await eventKit.deleteEvent(identifier: calId)
            } catch {
                print("⚠️ Failed to delete calendar event: \(error)")
            }
        }
        if let remId = item.reminderIdentifier {
            do {
                try await eventKit.deleteReminder(identifier: remId)
            } catch {
                print("⚠️ Failed to delete reminder: \(error)")
            }
        }
        
        // Elimina da app
        context.delete(item)

        // Notifica widget
        WidgetCenter.shared.reloadAllTimelines()
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

        if changed {
            WidgetCenter.shared.reloadAllTimelines()
        }
    }
}
