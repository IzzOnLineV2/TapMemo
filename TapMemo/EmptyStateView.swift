//
//  EmptyStateView.swift
//  TapMemo
//
//  Parte 3 · 3b — il primo avvio insegna in una riga cosa dire. L'esempio è
//  testo reale, non un'immagine: VoiceOver lo legge.
//

import SwiftUI

struct EmptyStateView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: TMSpace.xl) {
            VStack(alignment: .leading, spacing: TMSpace.m) {
                Text("Parla, ed è in calendario.")
                    .font(.largeTitle)
                    .foregroundStyle(.primary)

                Text("Tocca il cerchio e dì quando. TapMemo scrive il titolo e crea l'evento al posto tuo.")
                    .font(.body)
                    .foregroundStyle(.secondary)
            }

            VStack(alignment: .leading, spacing: TMSpace.s) {
                Text("Prova a dire")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)

                Text("«ricordami la spesa domani alle 3»")
                    .font(.headline)
                    .foregroundStyle(TMColor.accent)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(TMSpace.rowPadding)
            .tmCardSurface()

            VStack(alignment: .leading, spacing: TMSpace.xs) {
                Text("Capisce anche")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                Text("dopodomani, sabato 25, stasera, a mezzogiorno.")
                    .font(.footnote)
                    .foregroundStyle(.primary)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, TMSpace.screenMargin)
        .padding(.top, TMSpace.xl)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
