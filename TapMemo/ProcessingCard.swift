//
//  ProcessingCard.swift
//  TapMemo
//
//  Parte 3 · 3d — la card compare al posto del memo che sta nascendo, così la
//  posizione non salta quando arriva il risultato. Evidenziare la parte
//  temporale riconosciuta insegna il parser senza tutorial.
//

import SwiftUI

struct ProcessingCard: View {
    let transcript: String

    var body: some View {
        VStack(alignment: .leading, spacing: TMSpace.s) {
            highlightedTranscript

            HStack(spacing: TMSpace.s) {
                ProgressView()
                    .controlSize(.small)
                Text("Un attimo…")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(TMSpace.rowPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .tmCardSurface()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Sto creando il memo")
        .accessibilityValue(transcript)
    }

    /// La porzione letta come data/ora si stacca in accento.
    private var highlightedTranscript: some View {
        Group {
            if let range = MemoParser.temporalHighlight(in: transcript) {
                Text("«" + String(transcript[transcript.startIndex..<range.lowerBound]))
                    .foregroundStyle(.primary)
                + Text(String(transcript[range]))
                    .foregroundStyle(TMColor.accent)
                    .fontWeight(.semibold)
                + Text("»")
                    .foregroundStyle(.primary)
            } else {
                Text("«\(transcript)»")
                    .foregroundStyle(.primary)
            }
        }
        .font(.headline)
        .fontWeight(.regular)
    }
}
