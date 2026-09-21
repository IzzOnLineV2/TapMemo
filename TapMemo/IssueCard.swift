//
//  IssueCard.swift
//  TapMemo
//
//  Parte 3 · 3h — niente alert di sistema: l'errore è una card in linea, resta
//  leggibile, si può rileggere e non blocca l'app.
//

import SwiftUI
import UIKit

struct IssueCard: View {
    let issue: AppIssue
    let onDismiss: () -> Void

    @Environment(\.colorSchemeContrast) private var contrast

    /// Con Increase Contrast il bordo passa da 3 a 4 pt e il testo secondario
    /// sale a opacità piena.
    private var borderWidth: CGFloat { contrast == .increased ? 4 : 3 }

    var body: some View {
        VStack(alignment: .leading, spacing: TMSpace.m) {
            Label {
                Text(issue.title)
                    .font(.headline)
            } icon: {
                Image(systemName: issue.symbol)
                    .foregroundStyle(TMColor.error)
            }

            Text(issue.message)
                .font(.subheadline)
                .foregroundStyle(contrast == .increased ? .primary : .secondary)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: TMSpace.m) {
                if issue.opensSettings {
                    Button("Apri Impostazioni", action: openSettings)
                        .buttonStyle(.borderedProminent)
                        .tint(TMColor.accent)
                }

                Button(issue.dismissTitle, action: onDismiss)
                    .buttonStyle(.bordered)
                    .tint(TMColor.local)
            }
            .font(.subheadline)
        }
        .padding(TMSpace.rowPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: TMRadius.card, style: .continuous)
                .fill(TMColor.card)
        )
        .overlay(
            RoundedRectangle(cornerRadius: TMRadius.card, style: .continuous)
                .strokeBorder(TMColor.error.opacity(0.85), lineWidth: borderWidth)
        )
        .tmElevation()
        .accessibilityElement(children: .contain)
        .accessibilityLabel(issue.title)
        .accessibilityValue(issue.message)
    }

    private func openSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }
}
