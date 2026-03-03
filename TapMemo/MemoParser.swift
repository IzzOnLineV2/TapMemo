//
//  MemoParser.swift
//  TapMemo
//
//  Created by Stefania Izzo on 03/03/26.
//

import Foundation

struct ParsedMemo {
    let title: String
    let dueAt: Date?
}

struct MemoParser {
    
    // Punto di ingresso
    static func parse(_ text: String, now: Date = Date(), locale: Locale = Locale(identifier: "it-IT")) -> ParsedMemo {
        let cleaned = normalize(text)
        
        print("🔍 MemoParser input: '\(text)'")
        print("🔍 Normalized: '\(cleaned)'")
        
        // 1) Estrai data/ora
        let dueAt = extractDateTime(cleaned, now: now, locale: locale)
        
        if let date = dueAt {
            print("📅 Parsed date: \(date)")
            let formatter = DateFormatter()
            formatter.dateStyle = .short
            formatter.timeStyle = .short
            formatter.locale = locale
            print("📅 Formatted: \(formatter.string(from: date))")
        } else {
            print("📅 No date found")
        }
        
        // 2) Estrai titolo pulito
        let title = extractTitle(cleaned)
        print("📝 Title: '\(title)'")
        
        return ParsedMemo(title: title, dueAt: dueAt)
    }
    
    private static func normalize(_ s: String) -> String {
        s.trimmingCharacters(in: .whitespacesAndNewlines)
         .replacingOccurrences(of: "  ", with: " ")
         .lowercased()
    }
    
    private static func extractTitle(_ s: String) -> String {
        var t = s
        
        // Rimuovi prefissi comuni
        let prefixes = ["ricordami di ", "ricordami ", "promemoria ", "aggiungi appuntamento ", "aggiungi evento ", "aggiungi ", "mi ricordi di ", "mi ricordi ", "devo ", "fare "]
        for p in prefixes {
            if t.hasPrefix(p) { 
                t = String(t.dropFirst(p.count))
                break 
            }
        }
        
        // Rimuovi parte temporale: "domani", "oggi", "alle 3", "sabato 25", ecc.
        let cutWords = [
            " oggi", " domani", " dopodomani",
            " lunedì", " martedì", " mercoledì", " giovedì", " venerdì", " sabato", " domenica",
            " alle ", " ore ", " all' ", " all'una", " a mezzogiorno", " a mezzanotte"
        ]
        
        for w in cutWords {
            if let r = t.range(of: w) {
                t = String(t[..<r.lowerBound])
                break
            }
        }
        
        // Rimuovi numeri finali (come "25" in "unghie sabato 25")
        t = t.replacingOccurrences(of: #"\s+\d{1,2}$"#, with: "", options: .regularExpression)
        
        return t.trimmingCharacters(in: .whitespacesAndNewlines).capitalizedSentence()
    }
    
    private static func extractDateTime(_ s: String, now: Date, locale: Locale) -> Date? {
        let cal = Calendar.current
        let lowered = s
        
        print("  🕐 Extracting date/time from: '\(lowered)'")
        
        // 1) Determina il giorno base
        var baseDay: Date? = nil
        
        // "dopodomani"
        if lowered.contains("dopodomani") {
            baseDay = cal.date(byAdding: .day, value: 2, to: startOfDay(now))
            print("  📆 Found: dopodomani")
        }
        // "domani"
        else if lowered.contains("domani") {
            baseDay = cal.date(byAdding: .day, value: 1, to: startOfDay(now))
            print("  📆 Found: domani")
        }
        // "oggi"
        else if lowered.contains("oggi") {
            baseDay = startOfDay(now)
            print("  📆 Found: oggi")
        }
        // Giorno della settimana + eventuale numero (es: "sabato 25")
        else if let (weekday, dayNum) = extractWeekdayAndDay(lowered) {
            baseDay = nextWeekdayWithDay(weekday: weekday, dayNumber: dayNum, from: now, calendar: cal)
            print("  📆 Found: weekday \(weekday) + day \(dayNum)")
        }
        // Solo giorno della settimana (es: "sabato")
        else if let weekday = extractWeekday(lowered) {
            baseDay = nextWeekday(weekday, from: now, calendar: cal)
            print("  📆 Found: weekday \(weekday)")
        }
        // Solo numero di giorno (es: "25") - assume mese corrente o prossimo
        else if let dayNum = extractDayNumber(lowered) {
            baseDay = findNextDayInMonth(dayNum, from: now, calendar: cal)
            print("  📆 Found: day number \(dayNum)")
        } else {
            print("  📆 No day keyword found")
        }
        
        // 2) Estrai orario: "alle 3", "alle 16", "alle 15:30"
        let time = extractTimeComponents(lowered)
        if let t = time {
            print("  ⏰ Found time: \(t.hour):\(String(format: "%02d", t.minute))")
        } else {
            print("  ⏰ No time found")
        }
        
        // 3) Componi data finale
        
        // Se ho giorno
        if let day = baseDay {
            if let time = time {
                let result = cal.date(bySettingHour: time.hour, minute: time.minute, second: 0, of: day)
                print("  ✅ Combined: day + time")
                return result
            } else {
                // Default: 09:00 se non specifica orario ("spesa domani" → domani 09:00)
                let result = cal.date(bySettingHour: 9, minute: 0, second: 0, of: day)
                print("  ✅ Day only, defaulting to 09:00")
                return result
            }
        }
        
        // Se non ho giorno ma ho orario → oggi con quell'ora (o domani se già passata)
        if let time = time {
            var candidate = cal.date(bySettingHour: time.hour, minute: time.minute, second: 0, of: now)
            if let c = candidate, c < now {
                candidate = cal.date(byAdding: .day, value: 1, to: c)
                print("  ✅ Time only (past) → tomorrow")
            } else {
                print("  ✅ Time only → today")
            }
            return candidate
        }
        
        print("  ❌ No date/time extracted")
        return nil
    }
    
    private static func startOfDay(_ d: Date) -> Date {
        Calendar.current.startOfDay(for: d)
    }
    
    private static func extractWeekday(_ s: String) -> Int? {
        let map: [String: Int] = [
            "domenica": 1,
            "lunedì": 2, "lunedi": 2,
            "martedì": 3, "martedi": 3,
            "mercoledì": 4, "mercoledi": 4,
            "giovedì": 5, "giovedi": 5,
            "venerdì": 6, "venerdi": 6,
            "sabato": 7
        ]
        for (k, v) in map where s.contains(k) { return v }
        return nil
    }
    
    private static func extractWeekdayAndDay(_ s: String) -> (weekday: Int, day: Int)? {
        // Pattern: "sabato 25", "lunedì 3", ecc.
        guard let weekday = extractWeekday(s) else { return nil }
        
        // Cerca numero dopo il nome del giorno
        let weekdayNames = ["domenica", "lunedì", "lunedi", "martedì", "martedi", "mercoledì", "mercoledi", "giovedì", "giovedi", "venerdì", "venerdi", "sabato"]
        
        for name in weekdayNames where s.contains(name) {
            let pattern = name + #"\s+(\d{1,2})"#
            if let match = s.firstMatch(regex: pattern), match.count > 1 {
                if let dayNum = Int(match[1]) {
                    return (weekday, dayNum)
                }
            }
        }
        
        return nil
    }
    
    private static func extractDayNumber(_ s: String) -> Int? {
        // Cerca pattern tipo "il 25", "giorno 15"
        let patterns = [
            #"il\s+(\d{1,2})"#,
            #"giorno\s+(\d{1,2})"#
        ]
        
        for p in patterns {
            if let match = s.firstMatch(regex: p), match.count > 1 {
                return Int(match[1])
            }
        }
        
        return nil
    }
    
    private static func nextWeekday(_ weekday: Int, from now: Date, calendar: Calendar) -> Date? {
        var comps = DateComponents()
        comps.weekday = weekday
        return calendar.nextDate(after: now, matching: comps, matchingPolicy: .nextTime)
            .map { calendar.startOfDay(for: $0) }
    }
    
    private static func nextWeekdayWithDay(weekday: Int, dayNumber: Int, from now: Date, calendar: Calendar) -> Date? {
        // Trova il prossimo giorno che corrisponde sia al weekday che al numero del giorno
        let currentMonth = calendar.component(.month, from: now)
        let currentYear = calendar.component(.year, from: now)
        
        // Prova nel mese corrente
        if let date = calendar.date(from: DateComponents(year: currentYear, month: currentMonth, day: dayNumber)) {
            let dateWeekday = calendar.component(.weekday, from: date)
            if dateWeekday == weekday && date >= startOfDay(now) {
                return startOfDay(date)
            }
        }
        
        // Prova nel mese successivo
        let nextMonth = currentMonth == 12 ? 1 : currentMonth + 1
        let nextYear = currentMonth == 12 ? currentYear + 1 : currentYear
        
        if let date = calendar.date(from: DateComponents(year: nextYear, month: nextMonth, day: dayNumber)) {
            let dateWeekday = calendar.component(.weekday, from: date)
            if dateWeekday == weekday {
                return startOfDay(date)
            }
        }
        
        // Fallback: trova il prossimo weekday senza considerare il numero
        return nextWeekday(weekday, from: now, calendar: calendar)
    }
    
    private static func findNextDayInMonth(_ day: Int, from now: Date, calendar: Calendar) -> Date? {
        let currentYear = calendar.component(.year, from: now)
        let currentMonth = calendar.component(.month, from: now)
        
        // Prova mese corrente
        if let date = calendar.date(from: DateComponents(year: currentYear, month: currentMonth, day: day)),
           date >= startOfDay(now) {
            return startOfDay(date)
        }
        
        // Prova mese successivo
        let nextMonth = currentMonth == 12 ? 1 : currentMonth + 1
        let nextYear = currentMonth == 12 ? currentYear + 1 : currentYear
        
        if let date = calendar.date(from: DateComponents(year: nextYear, month: nextMonth, day: day)) {
            return startOfDay(date)
        }
        
        return nil
    }
    
    private static func extractTimeComponents(_ s: String) -> (hour: Int, minute: Int)? {
        // Patterns: "alle 3", "alle 15", "alle 15:30", "ore 9", "a mezzogiorno"
        
        // Special cases
        if s.contains("mezzogiorno") { return (12, 0) }
        if s.contains("mezzanotte") { return (0, 0) }
        
        let patterns = [
            #"alle\s+(\d{1,2})[:\.](\d{2})"#,  // "alle 15:30"
            #"ore\s+(\d{1,2})[:\.](\d{2})"#,   // "ore 9:15"
            #"alle\s+(\d{1,2})"#,               // "alle 3"
            #"ore\s+(\d{1,2})"#,                // "ore 9"
            #"all['\s]*(\d{1,2})"#              // "all'1", "all' 1"
        ]
        
        for p in patterns {
            if let match = s.firstMatch(regex: p), match.count > 1 {
                let h = Int(match[1]) ?? 0
                let m = match.count > 2 ? (Int(match[2]) ?? 0) : 0
                let adjusted = adjustHourHeuristic(h, in: s)
                return (adjusted, m)
            }
        }
        
        return nil
    }
    
    private static func adjustHourHeuristic(_ hour: Int, in s: String) -> Int {
        guard hour >= 0 && hour <= 23 else { return hour }
        
        // Se specifica "mattina" → lascia l'ora così
        if s.contains("mattina") || s.contains("mattino") { return hour }
        
        // Se specifica "sera" o "pomeriggio" → +12 se hour < 12
        if s.contains("sera") || s.contains("stasera") || s.contains("pomeriggio") {
            return hour < 12 ? hour + 12 : hour
        }
        
        // Default italiano: "alle 3" di solito significa 15:00 (pomeriggio)
        // Applica solo per ore 1-7 (1→13, 2→14, 3→15, ..., 7→19)
        if hour >= 1 && hour <= 7 {
            return hour + 12
        }
        
        return hour
    }
}

// MARK: - Helpers

private extension String {
    func firstMatch(regex pattern: String) -> [String]? {
        guard let r = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else { return nil }
        let ns = self as NSString
        guard let m = r.firstMatch(in: self, options: [], range: NSRange(location: 0, length: ns.length)) else { return nil }
        
        var out: [String] = []
        for i in 0..<m.numberOfRanges {
            let range = m.range(at: i)
            out.append(range.location == NSNotFound ? "" : ns.substring(with: range))
        }
        return out
    }
    
    func capitalizedSentence() -> String {
        guard !self.isEmpty else { return self }
        return self.prefix(1).uppercased() + self.dropFirst()
    }
}
