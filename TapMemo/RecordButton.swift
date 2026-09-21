//
//  RecordButton.swift
//  TapMemo
//
//  Parte 3 · 3a/3b — il pulsante sta in basso: raggiungibile con il pollice, in
//  auto, con una mano. 88 pt di target, ben oltre i 44 minimi.
//

import SwiftUI

struct RecordButton: View {
    let isRecording: Bool
    let isEnabled: Bool
    /// Nello stato vuoto pulsa una volta ogni 2,4 s per attirare il primo tap.
    var invitesTap: Bool = false
    let action: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var pulse = false

    private var tint: Color { isRecording ? TMColor.recording : TMColor.accent }

    var body: some View {
        Button(action: action) {
            ZStack {
                if invitesTap && !isRecording {
                    invitation
                }

                Circle()
                    .fill(tint)
                    .frame(width: TMSize.recordButton, height: TMSize.recordButton)
                    .shadow(color: tint.opacity(0.35), radius: 16, x: 0, y: 6)

                Image(systemName: isRecording ? "stop.fill" : "mic.fill")
                    .font(.system(size: 32, weight: .medium))
                    .foregroundStyle(.white)
            }
        }
        .buttonStyle(RecordButtonStyle())
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1 : 0.55)
        .animation(TMMotion.state, value: isRecording)
        .accessibilityLabel(isRecording ? Text("Ferma la registrazione") : Text("Registra un memo"))
        .accessibilityHint(isRecording ? Text("Tocca due volte per finire") : Text("Tocca due volte e parla"))
        .onAppear { pulse = invitesTap }
        .onChange(of: invitesTap) { _, newValue in pulse = newValue }
    }

    @ViewBuilder
    private var invitation: some View {
        if reduceMotion {
            // Con Reduce Motion il pulsare è sostituito da un anello statico.
            Circle()
                .strokeBorder(tint.opacity(0.35), lineWidth: 3)
                .frame(width: TMSize.recordButton + 22, height: TMSize.recordButton + 22)
        } else {
            Circle()
                .fill(tint.opacity(0.18))
                .frame(width: TMSize.recordButton, height: TMSize.recordButton)
                .scaleEffect(pulse ? 1.45 : 1)
                .opacity(pulse ? 0 : 1)
                .animation(.easeOut(duration: 1.6).repeatForever(autoreverses: false).delay(0.8),
                           value: pulse)
        }
    }
}

/// Scala 0.96 in 120 ms (token «tap»).
private struct RecordButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(TMMotion.tap, value: configuration.isPressed)
    }
}

// MARK: - Dock

/// Il pulsante con la sua didascalia, ancorato in fondo alla schermata.
struct RecordDock: View {
    let isRecording: Bool
    let isEnabled: Bool
    var invitesTap: Bool = false
    let action: () -> Void

    var body: some View {
        VStack(spacing: TMSpace.m) {
            RecordButton(isRecording: isRecording,
                         isEnabled: isEnabled,
                         invitesTap: invitesTap,
                         action: action)

            Text("Tocca e parla")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)
        }
        .padding(.top, TMSpace.l)
        .padding(.bottom, TMSpace.s)
        .frame(maxWidth: .infinity)
        .background(alignment: .top) {
            LinearGradient(colors: [TMColor.canvas.opacity(0), TMColor.canvas],
                           startPoint: .top, endPoint: .bottom)
                .frame(height: 28)
                .offset(y: -28)
                .allowsHitTesting(false)
        }
        .background(TMColor.canvas)
    }
}
