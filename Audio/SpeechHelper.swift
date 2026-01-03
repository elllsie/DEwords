//
//  Untitled.swift
//  testCalc
//
//  Created by 彭滢 on 2026/1/2.
//

import AVFoundation

final class SpeechHelper {

    static let shared = SpeechHelper()

    private let synthesizer = AVSpeechSynthesizer()
    private var isWarmedUp = false

    private init() {
        warmUp()
    }

    /// ⭐️ 预热语音引擎，避免首次播放卡顿
    private func warmUp() {
        guard !isWarmedUp else { return }

        let utterance = AVSpeechUtterance(string: " ")
        utterance.voice = AVSpeechSynthesisVoice(language: "de-DE")
        utterance.volume = 0

        synthesizer.speak(utterance)
        isWarmedUp = true
    }

    /// 对外调用的发音方法
    func speak(_ text: String) {
        guard !synthesizer.isSpeaking else { return }

        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "de-DE")
        utterance.rate = 0.45
        utterance.pitchMultiplier = 1.0

        synthesizer.speak(utterance)
    }
}
