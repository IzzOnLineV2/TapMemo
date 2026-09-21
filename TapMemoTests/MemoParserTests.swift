//
//  MemoParserTests.swift
//  TapMemoTests
//
//  Il parser è il cuore dell'app e l'unica parte che si può verificare senza
//  microfono: qui ci sono i casi che le immagini dell'App Store promettono.
//

import Testing
import Foundation
@testable import TapMemo

struct MemoParserTests {

    /// Lunedì 21 settembre 2026, ore 10:00 a Roma.
    private static let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/Rome")!
        return calendar
    }()

    private static let now = calendar.date(from: DateComponents(
        year: 2026, month: 9, day: 21, hour: 10, minute: 0))!

    private func parse(_ text: String, _ language: MemoLanguage) -> ParsedMemo {
        MemoParser.parse(text, now: Self.now, language: language, calendar: Self.calendar)
    }

    private func components(_ date: Date) -> DateComponents {
        Self.calendar.dateComponents([.year, .month, .day, .hour, .minute], from: date)
    }

    // MARK: - Italiano

    @Test("«alle 3» sono le 15, e il giorno è domani")
    func italianTomorrowAfternoon() throws {
        let parsed = parse("ricordami la spesa domani alle 3", MemoLanguageCatalog.italian)
        let due = try #require(parsed.dueAt)
        let parts = components(due)

        #expect(parsed.title == "La spesa")
        #expect(parts.day == 22)
        #expect(parts.month == 9)
        #expect(parts.hour == 15)
        #expect(parts.minute == 0)
    }

    @Test("Il titolo si taglia al marcatore che viene prima nella frase")
    func italianEarliestMarkerWins() throws {
        // Tagliando al primo marcatore della lista invece che al primo della
        // frase, il titolo sarebbe stato «Chiama mario alle 3».
        let parsed = parse("chiama mario alle 3 domani", MemoLanguageCatalog.italian)
        let due = try #require(parsed.dueAt)

        #expect(parsed.title == "Chiama mario")
        #expect(components(due).day == 22)
        #expect(components(due).hour == 15)
    }

    @Test("«stasera» è un giorno e un'ora insieme")
    func italianTonight() throws {
        let parsed = parse("cena con anna stasera", MemoLanguageCatalog.italian)
        let due = try #require(parsed.dueAt)

        #expect(parsed.title == "Cena con anna")
        #expect(components(due).day == 21)
        #expect(components(due).hour == 20)
    }

    @Test("«a mezzogiorno» senza giorno cade oggi")
    func italianNoon() throws {
        let parsed = parse("pranzo a mezzogiorno", MemoLanguageCatalog.italian)
        let due = try #require(parsed.dueAt)

        #expect(parsed.title == "Pranzo")
        #expect(components(due).day == 21)
        #expect(components(due).hour == 12)
    }

    @Test("Giorno della settimana con il numero che coincide")
    func italianWeekdayWithDay() throws {
        let parsed = parse("dentista sabato 26", MemoLanguageCatalog.italian)
        let due = try #require(parsed.dueAt)

        #expect(parsed.title == "Dentista")
        #expect(components(due).day == 26)
        #expect(components(due).hour == 9)
    }

    @Test("Quando numero e giorno non coincidono vince il giorno della settimana")
    func italianWeekdayWinsOverDay() throws {
        // Nel 2026 non esiste un sabato 25 né a settembre né a ottobre.
        let parsed = parse("dentista sabato 25", MemoLanguageCatalog.italian)
        let due = try #require(parsed.dueAt)

        #expect(components(due).day == 26)
    }

    @Test("Un memo senza data resta senza data")
    func italianNoDate() {
        let parsed = parse("devo chiamare il dentista", MemoLanguageCatalog.italian)

        #expect(parsed.dueAt == nil)
        #expect(parsed.title == "Chiamare il dentista")
    }

    // MARK: - Inglese

    @Test("«at 3» means 3 PM — la promessa dell'immagine 3 della scheda")
    func englishAtThreeMeansAfternoon() throws {
        let parsed = parse("remind me to buy milk tomorrow at 3", MemoLanguageCatalog.english)
        let due = try #require(parsed.dueAt)
        let parts = components(due)

        #expect(parsed.title == "Buy milk")
        #expect(parts.day == 22)
        #expect(parts.hour == 15)
    }

    @Test("Un meridiano esplicito batte l'abitudine")
    func englishMeridiem() throws {
        let morning = try #require(parse("call the dentist tomorrow at 9 am", MemoLanguageCatalog.english).dueAt)
        #expect(components(morning).hour == 9)

        let evening = try #require(parse("dinner at 8 pm", MemoLanguageCatalog.english).dueAt)
        #expect(components(evening).hour == 20)
        #expect(components(evening).day == 21)

        let noonish = try #require(parse("call mum at 12 pm", MemoLanguageCatalog.english).dueAt)
        #expect(components(noonish).hour == 12)
    }

    @Test("«tonight» e «at noon» in inglese")
    func englishDayPeriods() throws {
        let tonight = try #require(parse("dinner with anna tonight", MemoLanguageCatalog.english).dueAt)
        #expect(components(tonight).day == 21)
        #expect(components(tonight).hour == 20)

        let lunch = try #require(parse("lunch at noon", MemoLanguageCatalog.english).dueAt)
        #expect(components(lunch).hour == 12)
    }

    @Test("«saturday the 26th» con il suffisso ordinale")
    func englishWeekdayOrdinal() throws {
        let parsed = parse("dentist saturday the 26th", MemoLanguageCatalog.english)
        let due = try #require(parsed.dueAt)

        #expect(parsed.title == "Dentist")
        #expect(components(due).day == 26)
        #expect(components(due).hour == 9)
    }

    @Test("«the day after tomorrow» non viene letto come «tomorrow»")
    func englishDayAfterTomorrow() throws {
        let due = try #require(parse("pay the rent the day after tomorrow", MemoLanguageCatalog.english).dueAt)

        #expect(components(due).day == 23)
    }

    @Test("Un memo inglese senza data resta senza data")
    func englishNoDate() {
        let parsed = parse("call the dentist", MemoLanguageCatalog.english)

        #expect(parsed.dueAt == nil)
        #expect(parsed.title == "Call the dentist")
    }

    // MARK: - Evidenziazione e scelta della lingua

    @Test("L'evidenziazione parte dal primo marcatore")
    func temporalHighlight() throws {
        let italian = "ricordami la spesa domani alle 3"
        let range = try #require(MemoParser.temporalHighlight(in: italian, language: MemoLanguageCatalog.italian))
        #expect(String(italian[range]) == "domani alle 3")

        let english = "buy milk tomorrow at 3"
        let englishRange = try #require(MemoParser.temporalHighlight(in: english, language: MemoLanguageCatalog.english))
        #expect(String(english[englishRange]) == "tomorrow at 3")
    }

    @Test("La lingua del parser segue quella dell'interfaccia")
    func languageResolution() {
        #expect(MemoLanguageCatalog.resolve(preferred: ["en-GB"]).code == "en")
        #expect(MemoLanguageCatalog.resolve(preferred: ["it"]).code == "it")
        // Una lingua che non abbiamo ricade sull'italiano, lingua sorgente.
        #expect(MemoLanguageCatalog.resolve(preferred: ["fr-FR"]).code == "it")
    }
}
