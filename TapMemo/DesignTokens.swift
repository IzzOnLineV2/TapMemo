//
//  DesignTokens.swift
//  TapMemo
//
//  Design system del redesign (Parte 2 — token 2a/2c).
//  Sostituisce i Color.blue/.red sparsi in ContentView.swift e TapMemoWidget.swift.
//  Condiviso con l'estensione widget.
//

import SwiftUI

// MARK: - 2a · Palette

/// Accento indaco: fuori dai colori semantici di iOS (rosso Calendario, arancio
/// Promemoria, giallo Note) e non confondibile con il blu di sistema dei link.
enum TMColor {
    /// Pulsante registra, controlli. Corrisponde ad AccentColor nei due target.
    static let accent     = dynamic(light: 0x4B36D9, dark: 0x9A8BFF)
    /// Fondo icona, fondi poster, stato premuto.
    static let accentDeep = dynamic(light: 0x3A20BE, dark: 0x2A1690)

    /// «In Calendario» = accento: è l'esito che l'app promette.
    static let calendar   = dynamic(light: 0x4B36D9, dark: 0x9A8BFF)
    /// Ambra scura: 4.5:1 su fondo chiaro, cosa che l'arancio di sistema non fa.
    static let reminder   = dynamic(light: 0x9A5B00, dark: 0xF0A63C)
    /// «Solo in TapMemo»: assenza di destinazione, non errore.
    static let local      = dynamic(light: 0x6B6B75, dark: 0x9E9EA8)

    /// Solo nel segno di spunta della conferma, mai come fondo pieno.
    static let success    = dynamic(light: 0x17794C, dark: 0x3FD08A)
    /// Permessi negati, fallimento EventKit.
    static let error      = dynamic(light: 0xC0271E, dark: 0xFF7A6E)
    /// Magenta: distinguibile dal rosso errore e dall'indaco accento.
    static let recording  = dynamic(light: 0xD4145A, dark: 0xFF5C8A)

    /// Fondo app: un grigio con una punta di indaco, non grigio neutro.
    static let canvas     = dynamic(light: 0xF6F5FA, dark: 0x0E0D15)
    /// Riga memo. Sostituisce List + Divider.
    static let card       = dynamic(light: 0xFFFFFF, dark: 0x1B1926)

    private static func dynamic(light: UInt32, dark: UInt32) -> Color {
        Color(uiColor: UIColor { traits in
            UIColor(rgb: traits.userInterfaceStyle == .dark ? dark : light)
        })
    }
}

private extension UIColor {
    convenience init(rgb: UInt32) {
        self.init(red:   CGFloat((rgb >> 16) & 0xFF) / 255,
                  green: CGFloat((rgb >> 8) & 0xFF) / 255,
                  blue:  CGFloat(rgb & 0xFF) / 255,
                  alpha: 1)
    }
}

// MARK: - 2c · Spazi, raggi, materiali, movimento

/// Scala da 4. Margine schermo 20, padding riga 16, gap fra righe 10.
enum TMSpace {
    static let xs: CGFloat = 4
    static let s: CGFloat = 8
    static let m: CGFloat = 12
    static let l: CGFloat = 16
    static let xl: CGFloat = 24
    static let xxl: CGFloat = 32

    static let screenMargin: CGFloat = 20
    static let rowPadding: CGFloat = 16
    static let rowGap: CGFloat = 10
}

/// Concentrici al raggio del display (55).
enum TMRadius {
    static let badge: CGFloat = 10
    static let control: CGFloat = 14
    static let card: CGFloat = 20
    static let sheet: CGFloat = 28
}

enum TMMotion {
    /// 120 ms — tap, scala 0.96 del pulsante.
    static let tap = Animation.easeOut(duration: 0.12)
    /// 280 ms — idle ⇄ recording.
    static let state = Animation.spring(response: 0.35, dampingFraction: 0.8)
    /// 420 ms — foglio di conferma.
    static let reveal = Animation.spring(response: 0.5, dampingFraction: 0.75)
    /// 60 ms lineare, continuo — waveform.
    static let level = Animation.linear(duration: 0.06)
}

enum TMSize {
    /// Disco del pulsante registra: target 88 pt, ben oltre i 44 minimi.
    static let recordButton: CGFloat = 88
    static let recordButtonCompact: CGFloat = 64
    /// 12 barre nella waveform (3c).
    static let waveformBars = 12
}

// MARK: - Elevazione

extension View {
    /// Elevazione = materiale + bordo. Nessuna ombra oltre y 2 / blur 12 / 8%.
    func tmElevation() -> some View {
        shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 2)
    }

    /// Superficie card standard: fondo, raggio 20, bordo sottile, elevazione.
    func tmCardSurface(radius: CGFloat = TMRadius.card) -> some View {
        background(
            RoundedRectangle(cornerRadius: radius, style: .continuous)
                .fill(TMColor.card)
        )
        .overlay(
            RoundedRectangle(cornerRadius: radius, style: .continuous)
                .strokeBorder(Color.black.opacity(0.06), lineWidth: 1)
        )
        .tmElevation()
    }
}
