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
        Text(attributedTranscript)
            .font(.headline)
            .fontWeight(.regular)
            .foregroundStyle(.primary)
    }

    private var attributedTranscript: AttributedString {
        guard let range = MemoParser.temporalHighlight(in: transcript) else {
            return AttributedString("«\(transcript)»")
        }

        var result = AttributedString("«" + transcript[transcript.startIndex..<range.lowerBound])

        var temporal = AttributedString(String(transcript[range]))
        temporal.foregroundColor = TMColor.accent
        temporal.font = .headline.weight(.semibold)
        result += temporal

        result += AttributedString("»")
        return result
    }
}
