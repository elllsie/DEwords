import SwiftUI
import WatchKit

struct ContentView: View {

    // MARK: - 数据

    @State private var currentIndex: Int = 0
    private let words = WordRepository.words

    // MARK: - Digital Crown

    @State private var crownValue: Double = 0
    @State private var lastStep: Int = 0
    @FocusState private var isCrownFocused: Bool

    // MARK: - 发音防连点

    @State private var lastSpeakTime: Date = .distantPast
    private let speakCooldown: TimeInterval = 0.3

    // MARK: - 熟悉逻辑（Phase 1）

    @State private var familiarWordIDs: Set<String> = []
    @State private var showFamiliarHint: Bool = true
    @State private var showFamiliarFeedback: Bool = false

    // MARK: - 当前词

    private var currentWord: Word? {
        guard words.indices.contains(currentIndex) else { return nil }
        return words[currentIndex]
    }

    // MARK: - 切换

    private func nextWord() {
        guard currentIndex < words.count - 1 else { return }
        currentIndex += 1
    }

    private func previousWord() {
        guard currentIndex > 0 else { return }
        currentIndex -= 1
    }

    // MARK: - 标记熟悉（核心）

    private func markFamiliar() {
        guard let word = currentWord else { return }

        // 记录熟悉（暂存）
        familiarWordIDs.insert(word.text)

        // 触觉反馈
        WKInterfaceDevice.current().play(.success)

        // ✓ 动画（停留在当前词）
        withAnimation(.easeOut(duration: 0.2)) {
            showFamiliarFeedback = true
        }

        showFamiliarHint = false

        // 延迟切词，保证“这是 A 被标记”
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
            showFamiliarFeedback = false
            nextWord()
        }
    }

    // MARK: - View

    var body: some View {
        ZStack {

            // 主内容
            VStack {
                if let word = currentWord {
                    VStack(spacing: 6) {

                        Text(word.text)
                            .font(.title2)
                            .bold()
                            .multilineTextAlignment(.center)

                        // 音标点击发音
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

            // ✓ 熟悉反馈
            if showFamiliarFeedback {
                Image(systemName: "checkmark")
                    .font(.largeTitle)
                    .foregroundColor(.green)
                    .transition(.scale.combined(with: .opacity))
            }

            // 首次提示
            if showFamiliarHint {
                VStack {
                    Text("左滑标记为熟悉")
                        .font(.footnote)
                        .padding(6)
                        .background(.black.opacity(0.7))
                        .cornerRadius(8)
                        .transition(.opacity)
                    Spacer()
                }
                .padding(.top, 6)
            }
        }

        // MARK: - 手势（优先级非常重要）

        .gesture(
            DragGesture(minimumDistance: 20)
                .onEnded { value in

                    let h = value.translation.width
                    let v = value.translation.height

                    // 左滑：熟悉（强判定，防误触）
                    if h < -30 && abs(h) > abs(v) * 1.3 {
                        markFamiliar()
                        return
                    }

                    // 上下滑：切词
                    if v < -20 {
                        nextWord()
                    } else if v > 20 {
                        previousWord()
                    }
                }
        )

        // MARK: - Digital Crown

        .focusable(true)
        .focused($isCrownFocused)
        .digitalCrownRotation(
            $crownValue,
            from: -50,
            through: 50,
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

        // MARK: - 生命周期

        .onAppear {
            isCrownFocused = true

            // 提示只出现一次
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                withAnimation {
                    showFamiliarHint = false
                }
            }
        }
    }
}
