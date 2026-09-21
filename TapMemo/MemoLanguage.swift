//
//  MemoLanguage.swift
//  TapMemo
//
//  Le parole che cambiano da lingua a lingua. La matematica delle date sta in
//  MemoParser ed è la stessa per tutti: qui c'è solo il vocabolario.
//
//  Aggiungere una lingua significa aggiungere un MemoLanguage e verificarlo con
//  un madrelingua — non toccare il motore.
//

import Foundation

struct MemoLanguage {

    /// Un momento della giornata che vale anche come giorno: «stasera» è oggi,
    /// alle 20, se non si dice altro.
    struct DayPeriod {
        let words: [String]
        let dayOffset: Int
        let defaultHour: Int
    }

    /// Codice ISO della lingua (`it`, `en`) e locale da dare al riconoscitore vocale.
    let code: String
    let speechLocale: String

    // Giorni relativi. L'ordine conta: «dopodomani» contiene «domani», e
    // «the day after tomorrow» contiene «tomorrow».
    let dayAfterTomorrow: [String]
    let tomorrow: [String]
    let today: [String]

    /// Nome del giorno → indice `Calendar` (domenica = 1).
    let weekdays: [String: Int]

    let dayPeriods: [DayPeriod]

    let noon: [String]
    let midnight: [String]
    /// Parole che tengono l'ora com'è detta.
    let morning: [String]
    /// Parole che spostano al pomeriggio/sera le ore sotto le 12.
    let evening: [String]

    /// Prefissi da togliere dal titolo: «ricordami di…», «remind me to…».
    let titlePrefixes: [String]

    /// Marcatori che aprono la parte temporale della frase: tagliano il titolo e
    /// vengono evidenziati nella card di lavorazione (3d).
    let temporalMarkers: [String]

    /// Gruppo 1 = ora, gruppo 2 = minuti (facoltativo).
    let timePatterns: [String]
    /// Numero del giorno senza nome: «il 25», «on the 25th».
    let dayNumberPatterns: [String]
    /// Numero del giorno subito dopo il nome del giorno: «sabato 25», «saturday the 25th».
    let weekdayDaySuffix: String
    /// Gruppo 1 = `a` o `p` per am/pm. Vuoto dove la lingua non ha il meridiano.
    let meridiemPattern: String?

    /// Ore che, dette da sole, si intendono di pomeriggio: «alle 3» sono le 15,
    /// e in inglese «at 3» è ambiguo esattamente allo stesso modo.
    let afternoonHours: ClosedRange<Int>

    /// Ora di un memo con il giorno ma senza orario.
    let defaultHour: Int
}

// MARK: - Lingue supportate

enum MemoLanguageCatalog {

    static let italian = MemoLanguage(
        code: "it",
        speechLocale: "it-IT",
        dayAfterTomorrow: ["dopodomani"],
        tomorrow: ["domani"],
        today: ["oggi"],
        weekdays: [
            "domenica": 1,
            "lunedì": 2, "lunedi": 2,
            "martedì": 3, "martedi": 3,
            "mercoledì": 4, "mercoledi": 4,
            "giovedì": 5, "giovedi": 5,
            "venerdì": 6, "venerdi": 6,
            "sabato": 7
        ],
        dayPeriods: [
            .init(words: ["stamattina", "stamane"], dayOffset: 0, defaultHour: 9),
            .init(words: ["questo pomeriggio"], dayOffset: 0, defaultHour: 15),
            .init(words: ["stasera", "stanotte"], dayOffset: 0, defaultHour: 20)
        ],
        noon: ["mezzogiorno"],
        midnight: ["mezzanotte"],
        morning: ["mattina", "mattino", "stamattina", "stamane"],
        evening: ["sera", "stasera", "pomeriggio", "notte", "stanotte"],
        titlePrefixes: [
            "ricordami di ", "ricordami ", "mi ricordi di ", "mi ricordi ",
            "promemoria ", "aggiungi appuntamento ", "aggiungi evento ", "aggiungi ",
            "devo ", "fare "
        ],
        temporalMarkers: [
            " oggi", " domani", " dopodomani",
            " lunedì", " lunedi", " martedì", " martedi", " mercoledì", " mercoledi",
            " giovedì", " giovedi", " venerdì", " venerdi", " sabato", " domenica",
            " alle ", " ore ", " all'", " a mezzogiorno", " a mezzanotte",
            " stasera", " stamattina", " stamane", " stanotte", " questo pomeriggio"
            // Niente " il " / " giorno ": troppo comuni in italiano — taglierebbero
            // «chiamare il dentista» a «chiamare». Le date numeriche restano
            // riconosciute da dayNumberPatterns, solo non accorciano il titolo.
        ],
        timePatterns: [
            #"\balle\s+(\d{1,2})[:.](\d{2})"#,
            #"\bore\s+(\d{1,2})[:.](\d{2})"#,
            #"\balle\s+(\d{1,2})\b"#,
            #"\bore\s+(\d{1,2})\b"#,
            #"\ball['\s]*(\d{1,2})\b"#
        ],
        dayNumberPatterns: [
            #"\bil\s+(\d{1,2})\b"#,
            #"\bgiorno\s+(\d{1,2})\b"#
        ],
        weekdayDaySuffix: #"\s+(\d{1,2})\b"#,
        meridiemPattern: nil,
        afternoonHours: 1...7,
        defaultHour: 9
    )

    static let english = MemoLanguage(
        code: "en",
        speechLocale: "en-US",
        dayAfterTomorrow: ["the day after tomorrow", "day after tomorrow"],
        tomorrow: ["tomorrow"],
        today: ["today"],
        weekdays: [
            "sunday": 1, "monday": 2, "tuesday": 3, "wednesday": 4,
            "thursday": 5, "friday": 6, "saturday": 7
        ],
        dayPeriods: [
            .init(words: ["this morning"], dayOffset: 0, defaultHour: 9),
            .init(words: ["this afternoon"], dayOffset: 0, defaultHour: 15),
            .init(words: ["tonight", "this evening"], dayOffset: 0, defaultHour: 20)
        ],
        noon: ["noon", "midday"],
        midnight: ["midnight"],
        morning: ["morning", "this morning"],
        evening: ["evening", "tonight", "afternoon", "this afternoon", "night"],
        titlePrefixes: [
            "remind me to ", "remind me ", "reminder to ", "reminder ",
            "add an appointment ", "add appointment ", "add an event ", "add event ", "add ",
            "i need to ", "i have to ", "don't forget to ", "dont forget to "
        ],
        temporalMarkers: [
            " today", " tomorrow", " the day after tomorrow", " day after tomorrow",
            " sunday", " monday", " tuesday", " wednesday", " thursday", " friday", " saturday",
            " at ", " at noon", " at midnight",
            " tonight", " this morning", " this afternoon", " this evening",
            " on the ", " next "
        ],
        timePatterns: [
            #"\bat\s+(\d{1,2})[:.](\d{2})"#,
            #"\b(\d{1,2})[:.](\d{2})\s*[ap]\.?m\.?\b"#,
            #"\bat\s+(\d{1,2})\b"#,
            #"\b(\d{1,2})\s*[ap]\.?m\.?\b"#
        ],
        dayNumberPatterns: [
            #"\bon\s+the\s+(\d{1,2})(?:st|nd|rd|th)?\b"#,
            #"\bthe\s+(\d{1,2})(?:st|nd|rd|th)\b"#
        ],
        weekdayDaySuffix: #"\s+(?:the\s+)?(\d{1,2})(?:st|nd|rd|th)?\b"#,
        meridiemPattern: #"\d\s*([ap])\.?m\.?\b"#,
        afternoonHours: 1...7,
        defaultHour: 9
    )

    static let all: [MemoLanguage] = [italian, english]

    /// La lingua del parser segue **la lingua in cui l'app si sta mostrando**, non
    /// quella del dispositivo: se l'utente legge l'interfaccia in inglese si
    /// aspetta che il microfono ascolti in inglese. `preferredLocalizations`
    /// restituisce già la lingua scelta fra quelle che il bundle contiene.
    static var current: MemoLanguage {
        resolve(preferred: Bundle.main.preferredLocalizations)
    }

    static func resolve(preferred: [String]) -> MemoLanguage {
        for identifier in preferred {
            let code = Locale(identifier: identifier).language.languageCode?.identifier ?? identifier
            if let match = all.first(where: { $0.code == code }) { return match }
        }
        return italian
    }
}
