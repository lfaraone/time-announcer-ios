//
//  TimeAnnouncer.swift
//  time-announcer-ios
//
//  Created by Luke Faraone on 2025-11-04.
//

import Foundation
import AVFoundation
import Combine

@MainActor
class TimeAnnouncer: ObservableObject {
    @Published var authorizationStatus: AVSpeechSynthesizer.PersonalVoiceAuthorizationStatus = .notDetermined
    @Published var availableVoices: [AVSpeechSynthesisVoice] = []
    @Published var selectedVoiceIdentifier: String?
    @Published var isSpeaking = false

    private let speechSynthesizer = AVSpeechSynthesizer()
    private var timer: Timer?

    init() {
        checkAndRequestAuthorization()
    }
    
    func checkAndRequestAuthorization() {
        AVSpeechSynthesizer.requestPersonalVoiceAuthorization { status in
            Task { @MainActor in
                self.authorizationStatus = status
                if status == .authorized {
                    self.loadPersonalVoices()
                }
            }
        }
    }

    private func loadPersonalVoices() {
        let personalVoices = AVSpeechSynthesisVoice.speechVoices().filter {
            $0.voiceTraits.contains(.isPersonalVoice)
        }
        self.availableVoices = personalVoices
        if self.selectedVoiceIdentifier == nil, let firstVoice = personalVoices.first {
            self.selectedVoiceIdentifier = firstVoice.identifier
        }
    }

    func toggleSpeech() {
        if isSpeaking {
            stopAnnouncingTime()
        } else {
            startAnnouncingTime()
        }
    }

    private func startAnnouncingTime() {
        guard !isSpeaking else { return }
        isSpeaking = true
        // Announce immediately, then set up the timer to fire on the minute.
        announceTime()

        // Calculate the start of the next minute.
        let calendar = Calendar.current
        let now = Date()
        guard let nextMinute = calendar.nextDate(after: now, matching: DateComponents(second: 0), matchingPolicy: .nextTime) else {
            // Fallback to the old behavior if we can't calculate the next minute.
            self.timer = Timer.scheduledTimer(withTimeInterval: 60.0, repeats: true) { [weak self] _ in
                self?.announceTime()
            }
            return
        }
        
        // Create a timer that will fire at the top of the next minute, and every minute after.
        let newTimer = Timer(fire: nextMinute, interval: 60, repeats: true) { [weak self] _ in
            self?.announceTime()
        }
        RunLoop.main.add(newTimer, forMode: .common)
        self.timer = newTimer
    }

    private func stopAnnouncingTime() {
        guard isSpeaking else { return }
        isSpeaking = false
        timer?.invalidate()
        timer = nil
        speechSynthesizer.stopSpeaking(at: .immediate)
    }

    private func announceTime() {
        guard let voiceIdentifier = selectedVoiceIdentifier,
              let voice = AVSpeechSynthesisVoice(identifier: voiceIdentifier) else {
            // Can't find the selected voice, so stop.
            stopAnnouncingTime()
            return
        }

        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        let timeString = "The time is \(formatter.string(from: Date()))"

        let utterance: AVSpeechUtterance

       
        utterance = AVSpeechUtterance(string: timeString)
        //utterance.voice = voice
        // Recommended for Personal Voice
        utterance.prefersAssistiveTechnologySettings = true
        
        speechSynthesizer.speak(utterance)
    }
}
