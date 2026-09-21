//
//  RecordingOverlay.swift
//  TapMemo
//
//  Parte 3 · 3c — mentre l'utente parla: livello audio vero e trascrizione live.
//  Due vie d'uscita (✕ e swipe giù); il tap sul disco CONFERMA, non annulla.
//

import SwiftUI

struct RecordingOverlay: View {
    let level: Float
    let partialText: String
    let onFinish: () -> Void
    let onCancel: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            TMColor.canvas.ignoresSafeArea()

            VStack(spacing: 0) {
                header

                Spacer(minLength: TMSpace.l)

                transcript
                    .padding(.horizontal, TMSpace.screenMargin)

                Spacer(minLength: TMSpace.l)

                waveform
                    .frame(height: 64)
                    .padding(.horizontal, TMSpace.xxl)
                    .padding(.bottom, TMSpace.xl)

                RecordButton(isRecording: true, isEnabled: true, action: onFinish)

                Text("Tocca per finire · scorri giù per annullare")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .padding(.top, TMSpace.m)
                    .padding(.bottom, TMSpace.xl)
                    .accessibilityHidden(true)
            }
        }
        .gesture(
            DragGesture(minimumDistance: 40)
                .onEnded { value in
                    if value.translation.height > 60 { onCancel() }
                }
        )
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Sto ascoltando")
        .accessibilityValue(partialText)
    }

    private var header: some View {
        HStack {
            Label("Sto ascoltando", systemImage: "waveform")
                .font(.headline)
                .foregroundStyle(TMColor.recording)
                .labelStyle(.titleAndIcon)

            Spacer()

            Button(action: onCancel) {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .frame(width: 44, height: 44)
                    .background(Circle().fill(TMColor.card))
            }
            .accessibilityLabel("Annulla la registrazione")
        }
        .padding(.horizontal, TMSpace.screenMargin)
        .padding(.top, TMSpace.m)
    }

    /// L'ultima parola è ancora in ascolto: resta più chiara finché non si consolida.
    private var transcript: some View {
        Group {
            if partialText.isEmpty {
                Text("Dì quando…")
                    .font(.title2)
                    .foregroundStyle(.tertiary)
            } else {
                Text(attributedPartial).foregroundStyle(.primary)
            }
        }
        .font(.title2)
        .multilineTextAlignment(.leading)
        .frame(maxWidth: .infinity, alignment: .leading)
        .animation(TMMotion.state, value: partialText)
    }

    /// L'ultima parola resta più chiara finché il riconoscitore non la consolida.
    private var attributedPartial: AttributedString {
        guard let separator = partialText.lastIndex(of: " ") else {
            return AttributedString(partialText)
        }

        var result = AttributedString(partialText[partialText.startIndex..<separator] + " ")

        var trailing = AttributedString(String(partialText[partialText.index(after: separator)...]))
        trailing.foregroundColor = Color.secondary
        result += trailing

        return result
    }

    @ViewBuilder
    private var waveform: some View {
        if reduceMotion {
            // Reduce Motion: una sola barra di livello che cresce senza oscillare.
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(TMColor.recording.opacity(0.15))
                    Capsule()
                        .fill(TMColor.recording)
                        .frame(width: max(8, geo.size.width * CGFloat(level)))
                }
                .frame(height: 12)
                .frame(maxHeight: .infinity, alignment: .center)
            }
            .accessibilityHidden(true)
        } else {
            HStack(alignment: .center, spacing: 6) {
                ForEach(0..<TMSize.waveformBars, id: \.self) { index in
                    Capsule()
                        .fill(TMColor.recording)
                        .frame(height: barHeight(at: index))
                }
            }
            .animation(TMMotion.level, value: level)
            .accessibilityHidden(true)
        }
    }

    /// Ogni barra ha un peso fisso: il livello le muove tutte, la forma resta
    /// riconoscibile invece di diventare un istogramma casuale.
    private func barHeight(at index: Int) -> CGFloat {
        let weights: [CGFloat] = [0.35, 0.55, 0.8, 1.0, 0.7, 0.9, 1.0, 0.75, 0.95, 0.6, 0.45, 0.3]
        let weight = weights[index % weights.count]
        let amplitude = CGFloat(max(level, 0.04))
        return max(8, 64 * amplitude * weight)
    }
}
