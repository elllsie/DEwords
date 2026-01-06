import SwiftUI
import WatchKit

struct WordPracticeView: View {

    let words: [Word]
    let title: String

    // MARK: - 数据

    @State private var currentIndex: Int = 0

    // 用“步数”作为时间轴，避免熟悉词跳到词表末尾后永不再出现
    @State private var globalStep: Int = 0

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
    
    @State private var wordProgress: [String: WordProgress] = [:]
    
    //测试用
    @State private var debugMode = true
    
    //展开例句
    @State private var isExampleExpanded: Bool = false
    
    @State private var crownAccumulator: Double = 0




    // MARK: - 当前词

    private var currentWord: Word? {
        guard words.indices.contains(currentIndex) else { return nil }
        return words[currentIndex]
    }

    // MARK: - 切换

    private func nextWord() {
        guard !words.isEmpty else { return }
        isExampleExpanded = false
        let baseStep = globalStep

        // 循环扫描一圈：找“到期”或“未记录”的词
        for offset in 1...words.count {
            let candidateIndex = (currentIndex + offset) % words.count
            let candidateStep = baseStep + offset

            let word = words[candidateIndex]
            let progress = wordProgress[word.text]

            if progress == nil || candidateStep >= (progress?.nextAvailableStep ?? 0) {
                currentIndex = candidateIndex
                globalStep = candidateStep
                return
            }
        }

        // 兜底：极端情况下避免卡死
        currentIndex = (currentIndex + 1) % words.count
        globalStep = baseStep + 1
    }


    private func previousWord() {
        guard !words.isEmpty else { return }
        currentIndex = (currentIndex - 1 + words.count) % words.count
        // globalStep 不回退（保持时间轴单调递增，避免间隔逻辑倒退）
    }

    // MARK: - 标记熟悉（核心）

    private func markFamiliar() {
        guard let word = currentWord else { return }

        // 1️⃣ 取出或创建进度
        var progress = wordProgress[word.text] ?? WordProgress(
            familiarCount: 0,
            nextAvailableStep: globalStep + 1
        )

        // 2️⃣ 熟悉次数 +1
        progress.familiarCount += 1

        // 3️⃣ 用 SpacingEngine 计算“下次可出现 step”
        let nextStep = SpacingEngine.nextIndex(
            totalWords: words.count,
            currentIndex: globalStep,
            familiarCount: progress.familiarCount
        )

        progress.nextAvailableStep = nextStep

        // 4️⃣ 写回状态
        wordProgress[word.text] = progress

        // 5️⃣ 触觉反馈
        WKInterfaceDevice.current().play(.success)

        // 6️⃣ ✓ 动画（停留在当前词）
        withAnimation(.easeOut(duration: 0.2)) {
            showFamiliarFeedback = true
        }

        showFamiliarHint = false

        // 7️⃣ 延迟切词，确保“这是 A 被标记”
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

                        ViewThatFits(in: .vertical) {
                            Text(word.example)
                                .font(.footnote)
                                .multilineTextAlignment(.center)
                                .fixedSize(horizontal: false, vertical: true)

                            // 能完整显示 → 不需要展开
                              Text(word.example)
                                  .font(.footnote)
                                  .multilineTextAlignment(.center)
                                  .fixedSize(horizontal: false, vertical: true)

                              // 放不下 → 用可展开版本
                              Text(word.example)
                                  .font(.footnote)
                                  .multilineTextAlignment(.center)
                                  .lineLimit(isExampleExpanded ? nil : 2)
                                  .truncationMode(.tail)
                                  .fixedSize(horizontal: false, vertical: true)
                                  .onTapGesture {
                                      withAnimation {
                                          isExampleExpanded.toggle()
                                      }
                                  }


                            EmptyView()
                        }
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
            
            // //测试用
            // if debugMode, let word = currentWord {
            //     let progress = wordProgress[word.text]

            //     Text("""
            //     熟悉次数: \(progress?.familiarCount ?? 0)
            //     下次Step: \(progress?.nextAvailableStep ?? -1)
            //     当前Index: \(currentIndex)
            //     当前Step: \(globalStep)
            //     """)
            //     .font(.caption2)
            //     .foregroundColor(.gray)
            // }

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

        .navigationTitle(title)

        // MARK: - 手势（优先级非常重要）

        .gesture(
            DragGesture(minimumDistance: 20)
                .onEnded { value in

                    let h = value.translation.width
                    let v = value.translation.height

                    // 左滑：熟悉（强判定，防误触）
                    if h < -20 && abs(h) > abs(v) * 1.1 {
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
            from: -1000,
            through: 1000,
            by: 1.0,
            sensitivity: .medium,
            isContinuous: true,
            isHapticFeedbackEnabled: true
        )
        .onChange(of: crownValue) { _, newValue in
            let step = Int(newValue)

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

enum WordList: String, CaseIterable, Identifiable {
    case `default` = "words"
    case goetheA1 = "A1"
    case goetheA2 = "A2"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .default:
            return "默认"
        case .goetheA1:
            return "歌德A1"
        case .goetheA2:
            return "歌德A2"
        }
    }

    var resourceName: String { rawValue }
}

struct ContentView: View {
    @AppStorage("selectedWordList") private var selectedWordListRaw: String = WordList.default.rawValue

    private var selectedWordList: WordList {
        WordList(rawValue: selectedWordListRaw) ?? .default
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(WordList.allCases) { list in
                    NavigationLink(value: list) {
                        Text(list.title)
                    }
                }
            }
            .navigationTitle("选择词表")
            .navigationDestination(for: WordList.self) { list in
                WordPracticeView(
                    words: WordRepository.loadWords(resourceName: list.resourceName),
                    title: list.title
                )
            }
        }
    }
}
