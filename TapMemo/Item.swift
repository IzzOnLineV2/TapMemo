//
//  Item.swift
//  TapMemo
//
//  Created by Stefania Izzo on 03/03/26.
//

import Foundation
import SwiftData

@Model
class MemoItem {
    var id: UUID
    var originalText: String
    var normalizedTitle: String
    var dueAt: Date?
    var createdAt: Date
    var calendarIdentifier: String?
    var reminderIdentifier: String?
    var isShared: Bool

    init(originalText: String,
         normalizedTitle: String,
         dueAt: Date?,
         id: UUID = UUID(),
         createdAt: Date = Date(),
         calendarIdentifier: String? = nil,
         reminderIdentifier: String? = nil,
         isShared: Bool = false) {
        self.id = id
        self.originalText = originalText
        self.normalizedTitle = normalizedTitle
        self.dueAt = dueAt
        self.createdAt = createdAt
        self.calendarIdentifier = calendarIdentifier
        self.reminderIdentifier = reminderIdentifier
        self.isShared = isShared
    }

    var isInCalendar: Bool { calendarIdentifier != nil }
    var isInReminder: Bool { reminderIdentifier != nil }
    var isLocal: Bool { !isInCalendar && !isInReminder }
}
