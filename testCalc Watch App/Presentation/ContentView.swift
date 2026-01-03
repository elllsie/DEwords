import SwiftUI

struct ContentView: View {

    // ⭐️ 当前索引
    @State private var currentIndex: Int = 0

    // ⭐️ 词库
    private let words = WordRepository.words

    // Digital Crown
    @State private var crownValue: Double = 0
    @State private var lastStep: Int = 0
    @FocusState private var isCrownFocused: Bool

    // 发音防连点
    @State private var lastSpeakTime: Date = .distantPast
    private let speakCooldown: TimeInterval = 0.3

    // MARK: - 切换逻辑

    private func nextWord() {
        guard currentIndex < words.count - 1 else { return }
        currentIndex += 1
    }

    private func previousWord() {
        guard currentIndex > 0 else { return }
        currentIndex -= 1
    }

    private var currentWord: Word? {
        guard words.indices.contains(currentIndex) else { return nil }
        return words[currentIndex]
    }

    var body: some View {
        VStack {
            if let word = currentWord {
                VStack(spacing: 6) {

                    Text(word.text)
                        .font(.title2)
                        .bold()
                        .multilineTextAlignment(.center)

                    // 点击音标 → 发音
                    Text(word.phonetic)
                        .font(.footnote)
                        .foregroundColor(.green)
                        .onTapGesture {
                            let now = Date()
                            guard now.timeIntervalSince(lastSpeakTime) > speakCooldown else { return }
                            lastSpeakTime = now
                            SpeechHelper.shared.speak(word.text)
                        }

                    Text(word.meaning)
                        .font(.footnote)
                        .foregroundColor(.secondary)

                    Text(word.example)
                        .font(.footnote)
                        .multilineTextAlignment(.center)
                        .padding(.top, 4)
                }
                .padding()
            } else {
                Text("滑动或旋转表冠")
                    .foregroundColor(.gray)
            }
        }

        // ⭐️ 上下滑切换
        .gesture(
            DragGesture(minimumDistance: 20)
                .onEnded { value in
                    if value.translation.height < -20 {
                        nextWord()       // 上滑 → 下一词
                    } else if value.translation.height > 20 {
                        previousWord()  // 下滑 → 上一词
                    }
                }
        )

        // ⭐️ Digital Crown：一格一词（正反方向）
        .focusable(true)
        .focused($isCrownFocused)
        .digitalCrownRotation(
            $crownValue,
            from: -100,
            through: 100,
            by: 0.1,
            sensitivity: .medium,
            isContinuous: true,
            isHapticFeedbackEnabled: true
        )
        .onChange(of: crownValue) { _, newValue in
            let step = Int(newValue / 0.1)

            if step > lastStep {
                nextWord()
            } else if step < lastStep {
                previousWord()
            }

            lastStep = step
        }
        .onAppear {
            isCrownFocused = true
        }
    }
}
