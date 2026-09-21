//
//  EventKitService.swift
//  TapMemo
//
//  Created by Stefania Izzo on 03/03/26.
//

import Foundation
import EventKit

actor EventKitService {
    private let store = EKEventStore()
    
    // MARK: - Permissions
    
    func requestAccessCalendar() async throws -> Bool {
        if #available(iOS 17.0, *) {
            return try await store.requestFullAccessToEvents()
        } else {
            return try await withCheckedThrowingContinuation { continuation in
                store.requestAccess(to: .event) { granted, error in
                    if let error = error {
                        continuation.resume(throwing: error)
                    } else {
                        continuation.resume(returning: granted)
                    }
                }
            }
        }
    }
    
    func requestAccessReminders() async throws -> Bool {
        if #available(iOS 17.0, *) {
            return try await store.requestFullAccessToReminders()
        } else {
            return try await withCheckedThrowingContinuation { continuation in
                store.requestAccess(to: .reminder) { granted, error in
                    if let error = error {
                        continuation.resume(throwing: error)
                    } else {
                        continuation.resume(returning: granted)
                    }
                }
            }
        }
    }
    
    // MARK: - Create Calendar Event
    
    func createCalendarEvent(title: String, date: Date, isAllDay: Bool = false) async throws -> String {
        let granted = try await requestAccessCalendar()
        guard granted else { 
            throw NSError(domain: "TapMemo", code: 1, userInfo: [NSLocalizedDescriptionKey: "Calendar access denied"])
        }
        
        let event = EKEvent(eventStore: store)
        event.title = title
        event.startDate = date
        event.isAllDay = isAllDay
        
        if isAllDay {
            event.endDate = date
        } else {
            // Default: evento di 30 minuti
            event.endDate = Calendar.current.date(byAdding: .minute, value: 30, to: date) ?? date.addingTimeInterval(1800)
        }
        
        event.calendar = store.defaultCalendarForNewEvents
        
        try store.save(event, span: .thisEvent)
        return event.eventIdentifier
    }
    
    // MARK: - Create Reminder
    
    func createReminder(title: String, due: Date?) async throws -> String {
        let granted = try await requestAccessReminders()
        guard granted else { 
            throw NSError(domain: "TapMemo", code: 2, userInfo: [NSLocalizedDescriptionKey: "Reminders access denied"])
        }
        
        let reminder = EKReminder(eventStore: store)
        reminder.title = title
        reminder.calendar = store.defaultCalendarForNewReminders()
        
        if let due = due {
            let comps = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: due)
            reminder.dueDateComponents = comps
        }
        
        try store.save(reminder, commit: true)
        return reminder.calendarItemIdentifier
    }
    
    // MARK: - Delete
    
    func deleteEvent(identifier: String) async throws {
        guard let event = store.event(withIdentifier: identifier) else { return }
        try store.remove(event, span: .thisEvent)
    }
    
    func deleteReminder(identifier: String) async throws {
        guard let reminder = store.calendarItem(withIdentifier: identifier) as? EKReminder else { return }
        try store.remove(reminder, commit: true)
    }

    // MARK: - Update

    /// «Cambia ora» nel foglio di conferma (3e): sposta l'evento già creato
    /// invece di eliminarlo e ricrearlo, così l'identificatore resta valido.
    func updateEvent(identifier: String, date: Date, isAllDay: Bool = false) async throws {
        guard let event = store.event(withIdentifier: identifier) else {
            throw NSError(domain: "TapMemo", code: 3,
                          userInfo: [NSLocalizedDescriptionKey: "Event not found"])
        }

        event.startDate = date
        event.isAllDay = isAllDay
        if isAllDay {
            event.endDate = date
        } else {
            event.endDate = Calendar.current.date(byAdding: .minute, value: 30, to: date) ?? date.addingTimeInterval(1800)
        }

        try store.save(event, span: .thisEvent, commit: true)
    }

    // MARK: - Check Existence

    func eventExists(identifier: String) -> Bool {
        store.event(withIdentifier: identifier) != nil
    }

    func reminderExists(identifier: String) -> Bool {
        store.calendarItem(withIdentifier: identifier) is EKReminder
    }
}
