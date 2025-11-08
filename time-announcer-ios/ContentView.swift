//
//  ContentView.swift
//  time-announcer-ios
//
//  Created by Luke Faraone on 2025-11-04.
//

import SwiftUI
import AVFoundation

struct ContentView: View {
    @StateObject private var announcer = TimeAnnouncer()

    var body: some View {
        NavigationStack {
            VStack(spacing: 30) {
                Spacer()

                Group {
                    switch announcer.authorizationStatus {
                    case .notDetermined:
                        ProgressView()
                    case .denied:
                        Text("Personal Voice authorization has been denied. Please enable it in Settings > Accessibility > Personal Voice.")
                            .multilineTextAlignment(.center)
                    case .unsupported:
                        Text("Personal Voice is not supported on this device or operating system version.")
                            .multilineTextAlignment(.center)
                    case .authorized:
                        if announcer.availableVoices.isEmpty {
                            Text("No Personal Voices found. Please create one in Settings > Accessibility > Personal Voice.")
                                .multilineTextAlignment(.center)
                        } else {
                            VStack {
                                Text("Select a Personal Voice").font(.headline)
                                Picker("Select a Personal Voice", selection: $announcer.selectedVoiceIdentifier) {
                                    ForEach(announcer.availableVoices, id: \.identifier) { voice in
                                        Text("\(voice.name) (\(languageDisplayName(for: voice)))")
                                            .tag(voice.identifier as String?)
                                    }
                                }
                                .pickerStyle(.menu)
                                .labelsHidden()
                            }
                        }
                    @unknown default:
                        Text("An unknown error occurred regarding Personal Voice authorization.")
                            .multilineTextAlignment(.center)
                    }
                }
                .padding(.horizontal)

                Spacer()
                
                Button(action: announcer.toggleSpeech) {
                    Text(announcer.isSpeaking ? "Stop" : "Start Saying The Time")
                        .font(.headline)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(announcer.isSpeaking ? Color.red : Color.accentColor)
                        .foregroundColor(.white)
                        .clipShape(Capsule())
                }
                .padding()
                .disabled(announcer.authorizationStatus != .authorized || announcer.availableVoices.isEmpty)
            }
            .navigationTitle("Time Announcer")
        }
    }

    private func languageDisplayName(for voice: AVSpeechSynthesisVoice) -> String {
        // On some OS versions, a US English Personal Voice can be incorrectly identified
        // with the language code "zh-CH". We can correct the display text here.
        if voice.voiceTraits.contains(.isPersonalVoice) && voice.language == "zh-CH" {
            // Using Locale to get a user-friendly display name for en-US.
            return Locale.current.localizedString(forIdentifier: "en-US") ?? "English (US)"
        }
        
        // For other voices, or if the bug is fixed, display the reported language,
        // attempting to make it more user-friendly.
        return Locale.current.localizedString(forIdentifier: voice.language) ?? voice.language
    }
}

#Preview {
    ContentView()
}
