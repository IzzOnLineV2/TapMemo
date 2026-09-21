//
//  VoiceManager.swift
//  TapMemo
//
//  Created by Stefania Izzo on 03/03/26.
//
//  Redesign 3c — «Serve codice: VoiceManager deve pubblicare @Published var level
//  dal tap sul buffer e impostare shouldReportPartialResults = true».
//

import Foundation
import AVFoundation
import Speech
import Combine

@MainActor
final class VoiceManager: NSObject, ObservableObject {

    /// Sta registrando: il disco diventa magenta e compare la waveform.
    @Published private(set) var isRecording = false
    /// Livello del microfono 0…1, aggiornato dal tap sul buffer. Alimenta le 12 barre.
    @Published private(set) var level: Float = 0
    /// Trascrizione parziale, mostrata mentre l'utente parla.
    @Published private(set) var partialText: String = ""
    /// Permessi negati o audio non disponibile: diventa una card in linea (3h).
    @Published var issue: AppIssue?

    /// La lingua in cui l'app si sta mostrando: chi legge l'interfaccia in
    /// inglese si aspetta che il microfono ascolti in inglese.
    let language = MemoLanguageCatalog.current

    private let audioEngine = AVAudioEngine()
    private lazy var speechRecognizer = Self.makeRecognizer(for: language)
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?

    private var onFinal: ((String) -> Void)?
    private var didDeliver = false
    private var didCancel = false
    private var fallbackDelivery: Task<Void, Never>?

    /// Preferisce la variante regionale del dispositivo quando la lingua combacia
    /// (en-GB, it-CH): il riconoscimento è più preciso sull'accento locale.
    /// `SFSpeechRecognizer(locale:)` restituisce nil se la lingua non è supportata.
    private static func makeRecognizer(for language: MemoLanguage) -> SFSpeechRecognizer? {
        let device = Locale.current
        if device.language.languageCode?.identifier == language.code,
           let regional = SFSpeechRecognizer(locale: device) {
            return regional
        }
        return SFSpeechRecognizer(locale: Locale(identifier: language.speechLocale))
    }

    // MARK: - Permessi

    func requestPermissions() async {
        _ = await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { continuation.resume(returning: $0) }
        }
        _ = await AVAudioApplication.requestRecordPermission()
    }

    /// Il permesso mancante è un esito previsto, non un errore da lanciare:
    /// diventa la card 3h con l'azione giusta.
    private func blockingPermissionIssue() -> AppIssue? {
        if AVAudioApplication.shared.recordPermission == .denied { return .microphoneDenied }
        switch SFSpeechRecognizer.authorizationStatus() {
        case .denied, .restricted: return .speechDenied
        default: break
        }
        return nil
    }

    // MARK: - Registrazione

    func startRecording(onFinal: @escaping (String) -> Void) {
        guard !isRecording else { return }

        if let permissionIssue = blockingPermissionIssue() {
            issue = permissionIssue
            Haptics.error()
            return
        }

        self.onFinal = onFinal
        didDeliver = false
        didCancel = false
        partialText = ""
        level = 0
        issue = nil

        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.record, mode: .measurement, options: .duckOthers)
            try session.setActive(true, options: .notifyOthersOnDeactivation)

            let request = SFSpeechAudioBufferRecognitionRequest()
            // 3c: la trascrizione si vede mentre l'utente parla.
            request.shouldReportPartialResults = true
            request.requiresOnDeviceRecognition = false
            recognitionRequest = request

            recognitionTask = speechRecognizer?.recognitionTask(with: request) { [weak self] result, error in
                Task { @MainActor in
                    guard let self else { return }
                    if let result {
                        self.partialText = result.bestTranscription.formattedString
                        if result.isFinal { self.deliver(self.partialText) }
                    }
                    if error != nil, !self.didDeliver {
                        // Il riconoscitore chiude dopo endAudio: se abbiamo del
                        // testo è comunque un esito buono.
                        self.deliver(self.partialText)
                    }
                }
            }

            let inputNode = audioEngine.inputNode
            let format = inputNode.outputFormat(forBus: 0)

            inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self] buffer, _ in
                request.append(buffer)
                let value = VoiceManager.normalizedLevel(of: buffer)
                Task { @MainActor in self?.level = value }
            }

            audioEngine.prepare()
            try audioEngine.start()
            isRecording = true
            Haptics.tap()

        } catch {
            teardownAudio()
            issue = .recordingUnavailable(error.localizedDescription)
            Haptics.error()
        }
    }

    /// Tap sul disco: conferma. Il testo finale arriva dal riconoscitore.
    func stopRecording() {
        guard isRecording else { return }
        teardownAudio()
        recognitionRequest?.endAudio()
        isRecording = false
        level = 0

        // Se il riconoscitore non chiude entro un attimo, consegniamo il parziale:
        // meglio un memo con il testo che si vedeva a schermo che nessun memo.
        fallbackDelivery?.cancel()
        fallbackDelivery = Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(1500))
            guard let self, !Task.isCancelled else { return }
            await MainActor.run { self.deliver(self.partialText) }
        }
    }

    /// Swipe giù o ✕: annulla e scarta. Nessun memo viene creato.
    func cancelRecording() {
        guard isRecording else { return }
        didCancel = true
        teardownAudio()
        recognitionTask?.cancel()
        recognitionRequest?.endAudio()
        recognitionTask = nil
        recognitionRequest = nil
        isRecording = false
        level = 0
        partialText = ""
        onFinal = nil
        Haptics.warning()
    }

    // MARK: - Interni

    private func deliver(_ text: String) {
        guard !didDeliver, !didCancel else { return }
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmed.isEmpty else {
            // Un parziale vuoto mentre si parla è normale; a registrazione finita
            // significa che non è arrivato niente di comprensibile (3h).
            guard !isRecording else { return }
            didDeliver = true
            fallbackDelivery?.cancel()
            fallbackDelivery = nil
            onFinal = nil
            recognitionTask = nil
            recognitionRequest = nil
            issue = .notUnderstood
            Haptics.error()
            return
        }

        didDeliver = true
        fallbackDelivery?.cancel()
        fallbackDelivery = nil

        let callback = onFinal
        onFinal = nil
        recognitionTask = nil
        recognitionRequest = nil

        if isRecording {
            teardownAudio()
            isRecording = false
            level = 0
        }

        Haptics.success()
        callback?(trimmed)
    }

    private func teardownAudio() {
        if audioEngine.isRunning { audioEngine.stop() }
        audioEngine.inputNode.removeTap(onBus: 0)
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    /// RMS del buffer portato in scala 0…1: -50 dB è silenzio, -5 dB voce piena.
    nonisolated private static func normalizedLevel(of buffer: AVAudioPCMBuffer) -> Float {
        guard let channel = buffer.floatChannelData?[0] else { return 0 }
        let count = Int(buffer.frameLength)
        guard count > 0 else { return 0 }

        var sum: Float = 0
        for index in 0..<count {
            let sample = channel[index]
            sum += sample * sample
        }

        let rms = sqrt(sum / Float(count))
        let decibels = 20 * log10(max(rms, 1e-7))
        return min(max((decibels + 50) / 45, 0), 1)
    }
}
