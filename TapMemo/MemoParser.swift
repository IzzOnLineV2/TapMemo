//
//  MemoParser.swift
//  TapMemo
//
//  Created by Stefania Izzo on 03/03/26.
//
//  Da frase parlata a (titolo, data). Il motore è neutro rispetto alla lingua:
//  tutto il vocabolario sta in MemoLanguage, la matematica delle date è qui.
//

import Foundation

struct ParsedMemo {
    let title: String
    let dueAt: Date?
}

struct MemoParser {

    // MARK: - Ingresso

    static func parse(_ text: String,
                      now: Date = Date(),
                      language: MemoLanguage = MemoLanguageCatalog.current,
                      calendar: Calendar = .current) -> ParsedMemo {

        let cleaned = normalize(text)
        let dueAt = extractDateTime(cleaned, now: now, language: language, calendar: calendar)
        let title = extractTitle(cleaned, language: language)

        #if DEBUG
        print("🔍 [\(language.code)] '\(text)' → titolo '\(title)', data \(dueAt.map(String.init(describing:)) ?? "nessuna")")
        #endif

        return ParsedMemo(title: title, dueAt: dueAt)
    }

    private static func normalize(_ s: String) -> String {
        s.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
            .lowercased()
    }

    // MARK: - Titolo

    private static func extractTitle(_ s: String, language: MemoLanguage) -> String {
        var t = s

        for prefix in language.titlePrefixes where t.hasPrefix(prefix) {
            t = String(t.dropFirst(prefix.count))
            break
        }

        // Si taglia al marcatore che viene PRIMA nella frase, non al primo della
        // lista: in «chiama mario alle 3 domani» la parte da togliere comincia da
        // «alle», non da «domani».
        if let cut = earliestMarker(in: t, language: language) {
            t = String(t[..<cut])
        }

        // Numero rimasto in coda, come il «25» di «unghie sabato 25».
        t = t.replacingOccurrences(of: #"\s+\d{1,2}(?:st|nd|rd|th)?$"#, with: "", options: .regularExpression)

        return t.trimmingCharacters(in: .whitespacesAndNewlines).capitalizedSentence()
    }

    private static func earliestMarker(in text: String, language: MemoLanguage) -> String.Index? {
        var earliest: String.Index?
        for marker in language.temporalMarkers {
            guard let found = text.range(of: marker, options: [.caseInsensitive, .diacriticInsensitive]) else { continue }
            if earliest == nil || found.lowerBound < earliest! { earliest = found.lowerBound }
        }
        return earliest
    }

    // MARK: - Data e ora

    private static func extractDateTime(_ s: String,
                                        now: Date,
                                        language: MemoLanguage,
                                        calendar: Calendar) -> Date? {

        var baseDay: Date?
        var impliedHour: Int?

        // 1) Il giorno. L'ordine conta: «dopodomani» contiene «domani».
        if contains(s, language.dayAfterTomorrow) {
            baseDay = calendar.date(byAdding: .day, value: 2, to: calendar.startOfDay(for: now))
        } else if contains(s, language.tomorrow) {
            baseDay = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: now))
        } else if contains(s, language.today) {
            baseDay = calendar.startOfDay(for: now)
        } else if let (weekday, dayNumber) = extractWeekdayAndDay(s, language: language) {
            baseDay = nextWeekday(weekday, matchingDay: dayNumber, from: now, calendar: calendar)
        } else if let weekday = extractWeekday(s, language: language) {
            baseDay = nextWeekday(weekday, matchingDay: nil, from: now, calendar: calendar)
        } else if let period = language.dayPeriods.first(where: { contains(s, $0.words) }) {
            // «stasera» è un giorno e un'ora insieme.
            baseDay = calendar.date(byAdding: .day, value: period.dayOffset, to: calendar.startOfDay(for: now))
            impliedHour = period.defaultHour
        } else if let dayNumber = extractDayNumber(s, language: language) {
            baseDay = nextDate(withDay: dayNumber, from: now, calendar: calendar)
        }

        // 2) L'ora.
        let time = extractTime(s, language: language)

        // 3) Composizione.
        if let day = baseDay {
            let hour = time?.hour ?? impliedHour ?? language.defaultHour
            let minute = time?.minute ?? 0
            return calendar.date(bySettingHour: hour, minute: minute, second: 0, of: day)
        }

        // Ora senza giorno: oggi, o domani se è già passata.
        if let time {
            guard let candidate = calendar.date(bySettingHour: time.hour, minute: time.minute, second: 0, of: now) else {
                return nil
            }
            return candidate < now ? calendar.date(byAdding: .day, value: 1, to: candidate) : candidate
        }

        return nil
    }

    private static func contains(_ s: String, _ words: [String]) -> Bool {
        words.contains { s.contains($0) }
    }

    // MARK: - Giorni

    private static func extractWeekday(_ s: String, language: MemoLanguage) -> Int? {
        for (name, index) in language.weekdays where s.contains(name) { return index }
        return nil
    }

    /// «sabato 25», «saturday the 25th».
    private static func extractWeekdayAndDay(_ s: String, language: MemoLanguage) -> (weekday: Int, day: Int)? {
        for (name, index) in language.weekdays where s.contains(name) {
            let pattern = NSRegularExpression.escapedPattern(for: name) + language.weekdayDaySuffix
            if let match = s.firstMatch(regex: pattern), match.count > 1, let day = Int(match[1]) {
                return (index, day)
            }
        }
        return nil
    }

    private static func extractDayNumber(_ s: String, language: MemoLanguage) -> Int? {
        for pattern in language.dayNumberPatterns {
            if let match = s.firstMatch(regex: pattern), match.count > 1, let day = Int(match[1]) {
                return day
            }
        }
        return nil
    }

    /// Il prossimo giorno della settimana; se è indicato anche il numero, il
    /// primo in cui i due coincidono. Se non coincidono mai vince il giorno
    /// della settimana, che è quello che l'utente ha detto per primo.
    private static func nextWeekday(_ weekday: Int, matchingDay day: Int?, from now: Date, calendar: Calendar) -> Date? {
        if let day {
            for monthsAhead in 0...1 {
                guard let month = calendar.date(byAdding: .month, value: monthsAhead, to: now) else { continue }
                var components = calendar.dateComponents([.year, .month], from: month)
                components.day = day
                if let candidate = calendar.date(from: components),
                   calendar.component(.weekday, from: candidate) == weekday,
                   candidate >= calendar.startOfDay(for: now) {
                    return calendar.startOfDay(for: candidate)
                }
            }
        }

        var components = DateComponents()
        components.weekday = weekday
        return calendar.nextDate(after: now, matching: components, matchingPolicy: .nextTime)
            .map { calendar.startOfDay(for: $0) }
    }

    private static func nextDate(withDay day: Int, from now: Date, calendar: Calendar) -> Date? {
        for monthsAhead in 0...1 {
            guard let month = calendar.date(byAdding: .month, value: monthsAhead, to: now) else { continue }
            var components = calendar.dateComponents([.year, .month], from: month)
            components.day = day
            if let candidate = calendar.date(from: components),
               candidate >= calendar.startOfDay(for: now) {
                return calendar.startOfDay(for: candidate)
            }
        }
        return nil
    }

    // MARK: - Ore

    private static func extractTime(_ s: String, language: MemoLanguage) -> (hour: Int, minute: Int)? {
        if contains(s, language.noon) { return (12, 0) }
        if contains(s, language.midnight) { return (0, 0) }

        for pattern in language.timePatterns {
            guard let match = s.firstMatch(regex: pattern), match.count > 1,
                  let hour = Int(match[1]), (0...23).contains(hour) else { continue }

            let minute = match.count > 2 ? (Int(match[2]) ?? 0) : 0
            guard (0...59).contains(minute) else { continue }

            return (adjustedHour(hour, in: s, language: language), minute)
        }

        return nil
    }

    /// «alle 3» sono le 15 — e in inglese «at 3» è ambiguo allo stesso modo.
    /// Un meridiano esplicito batte tutto, poi le parole del momento della
    /// giornata, poi l'abitudine.
    private static func adjustedHour(_ hour: Int, in s: String, language: MemoLanguage) -> Int {
        if let pattern = language.meridiemPattern,
           let match = s.firstMatch(regex: pattern), match.count > 1 {
            let isPM = match[1].lowercased() == "p"
            if isPM { return hour < 12 ? hour + 12 : hour }
            return hour == 12 ? 0 : hour
        }

        if contains(s, language.morning) { return hour }
        if contains(s, language.evening) { return hour < 12 ? hour + 12 : hour }
        if language.afternoonHours.contains(hour) { return hour + 12 }

        return hour
    }

    // MARK: - Evidenziazione della parte temporale (3d)

    /// La porzione di trascrizione letta come data/ora, dal primo marcatore alla
    /// fine della frase: evidenziarla insegna il parser senza un tutorial.
    static func temporalHighlight(in text: String,
                                  language: MemoLanguage = MemoLanguageCatalog.current) -> Range<String.Index>? {
        guard var start = earliestMarker(in: text, language: language) else { return nil }

        // I marcatori iniziano con lo spazio di separazione: non va evidenziato.
        if text[start].isWhitespace { start = text.index(after: start) }
        guard start < text.endIndex else { return nil }

        return start..<text.endIndex
    }
}

// MARK: - Helpers

private extension String {
    func firstMatch(regex pattern: String) -> [String]? {
        guard let expression = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else { return nil }
        let ns = self as NSString
        guard let match = expression.firstMatch(in: self, range: NSRange(location: 0, length: ns.length)) else { return nil }

        return (0..<match.numberOfRanges).map { index in
            let range = match.range(at: index)
            return range.location == NSNotFound ? "" : ns.substring(with: range)
        }
    }

    func capitalizedSentence() -> String {
        guard !isEmpty else { return self }
        return prefix(1).uppercased() + dropFirst()
    }
}
