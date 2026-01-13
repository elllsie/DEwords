import SwiftUI
import WatchKit

struct WordPracticeView: View {

    @StateObject var scheduler: WordScheduler
    let title: String

    // UI 状态
    @State private var showHint = true
    @State private var showFamiliarFeedback = false
    @State private var showUnfamiliarFeedback = false

    @State private var isExampleExpanded = false
    @State private var showExampleTranslation = false

    @State private var crownValue: Double = 0
    @State private var lastStep: Int = 0
    @FocusState private var isCrownFocused: Bool

    @AppStorage("learningLanguage") private var learningLanguage: String = "zh"

    var body: some View {
        ZStack {
            if let word = scheduler.currentWord {
                wordView(word)
                    .id(word.id) // ⭐️ 必须
                    .transition(wordTransition)
            }
            
            // ② 熟悉 / 不熟 反馈（必须在 ZStack 里）
            if showFamiliarFeedback {
                feedbackView(text: familiarText, color: .green)
            }

            if showUnfamiliarFeedback {
                feedbackView(text: unfamiliarText, color: .yellow)
            }

            // ③ 新手提示
            if showHint {
                hintView
            }
        }
        .animation(.easeOut(duration: 0.16), value: scheduler.currentWord?.id)
        .contentShape(Rectangle())
        .navigationTitle(title)
//        .gesture(gesture)
        .simultaneousGesture(gesture)
        .focusable(true)
        .focused($isCrownFocused)
//        .digitalCrownRotation(
//            $crownValue,
//            from: -500,
//            through: 500,
//            by: 5
//        )
        .crownStepper(
            crownValue: $crownValue,
            threshold: isExampleExpanded ? 999 : 5,
            by: 1,
            onStepForward: {
                scheduler.next()
            },
            onStepBackward: {
                scheduler.previous()
            }
        )

        


//        .onChange(of: crownValue) { _, newValue in
//            let step = Int(newValue)
//            if step > lastStep {
//                scheduler.next()
//            } else if step < lastStep {
//                scheduler.previous()
//            }
//            lastStep = step
//        }
        
        .onChange(of: scheduler.currentWord?.id) { _ in
            isExampleExpanded = false
            showExampleTranslation = false
        }

        .onAppear {
            isCrownFocused = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                withAnimation {
                    showHint = false
                }
            }
        }
    }
}


private extension WordPracticeView {
    @ViewBuilder
    func wordView(_ word: Word) -> some View {
        VStack(spacing: 6) {

            Text(word.text)
                .font(.title2)
                .bold()
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.7)

            Text(word.phonetic)
                .font(.footnote)
                .foregroundColor(.green)
                .onTapGesture {
                    SpeechHelper.shared.speak(word.text)
                }

            Text(word.displayMeaning)
                .font(.footnote)
                .foregroundColor(.secondary)

            VStack(spacing: 4) {
//                Text(word.example)
//                    .font(.footnote)
//                    .multilineTextAlignment(.center)
//                    .lineLimit(isExampleExpanded ? nil : 2)
//                    .truncationMode(.tail)
//                    .onTapGesture {
//                        showExampleTemporarily()
//                    }
                Text(word.example)
                    .font(.footnote)
                    .multilineTextAlignment(.center)
                    .lineLimit(isExampleExpanded ? nil : 2)
                    .truncationMode(.tail)
                    .contentShape(Rectangle())

                    // ✅ 单击
                    .onTapGesture {
                        showExampleTemporarily()
                    }
                    .onLongPressGesture(minimumDuration: 0.4) {
                        withAnimation(.easeOut(duration: 0.2)) {
                            isExampleExpanded.toggle()
                        }
                        WKInterfaceDevice.current().play(.click)
                    }

//                    // ✅ 双击（必须显式 TapGesture）
//                    .highPriorityGesture(
//                        TapGesture(count: 2)
//                            .onEnded {
//                                withAnimation(.easeOut(duration: 0.2)) {
//                                    isExampleExpanded.toggle()
//                                }
//                                WKInterfaceDevice.current().play(.click)
//                            }
//                    )


                if showExampleTranslation,
                   let translation = exampleTranslation(for: word) {
                    Text(translation)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
//                        .transition(
//                            .move(edge: .top)
//                            .combined(with: .opacity)
//                        )
                 }
                }
            
//            .animation(.easeOut(duration: 0.18), value: showExampleTranslation)
            .frame(maxHeight: 90) // ⭐️ 非常关键：限制滚动区域高度
        }

    }
    
    var wordTransition: AnyTransition {
        switch scheduler.moveDirection {
        case .forward:
            return .asymmetric(
                insertion: .move(edge: .bottom).combined(with: .opacity),
                removal: .move(edge: .top).combined(with: .opacity)
            )
        case .backward:
            return .asymmetric(
                insertion: .move(edge: .top).combined(with: .opacity),
                removal: .move(edge: .bottom).combined(with: .opacity)
            )
        }
    }


    var familiarText: String {
        learningLanguage == "en" ? "Familiar" : "熟悉"
    }

    var unfamiliarText: String {
        learningLanguage == "en" ? "Review later" : "再看一下"
    }

    var hintView: some View {
        VStack {
            Text(learningLanguage == "en"
                 ? "← Familiar   Review →\n↑ ↓ Rotate Crown\nSwitch words\n"
                 : "← 熟悉   不熟 →\n↑ ↓ 旋转表冠\n切换单词\n")
                .font(.footnote)
                .padding(8)
                .background(.black.opacity(0.7))
                .cornerRadius(8)
            Spacer()
        }
        .padding(.top, 6)
    }
    
    func exampleTranslation(for word: Word) -> String? {
        switch learningLanguage {
        case "zh":
            return word.exampleZh
        case "en":
            return word.exampleEn
        default:
            return nil
        }
    }
    
    
    func showExampleTemporarily() {
        guard !showExampleTranslation else { return }

        withAnimation(.easeIn(duration: 0.15)) {
            showExampleTranslation = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
            withAnimation(.easeOut(duration: 0.2)) {
                showExampleTranslation = false
            }
        }
    }


    func feedbackView(text: String, color: Color) -> some View {
        Text(text)
            .font(.footnote)
            .padding(6)
            .background(color.opacity(0.8))
            .cornerRadius(6)
    }

    var gesture: some Gesture {
        DragGesture(minimumDistance: 20)
            .onEnded { value in
                let h = value.translation.width
                let v = value.translation.height

                          
                // ← 熟悉（横向必须“非常横”）
                if h < -25 && abs(h) > abs(v) * 1.8 {
                    handleFamiliar()
                    return
                }

                // → 不熟
                if h > 25 && abs(h) > abs(v) * 1.8 {
                    handleUnfamiliar()
                    return
                }

                // ↑ 下一个
                if v < -30 {
                    scheduler.next()
                    return
                }

                // ↓ 上一个
                if v > 30 {
                    scheduler.previous()
                    return
                }
            }
    }


    func flashFamiliar() {
        showFamiliarFeedback = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            showFamiliarFeedback = false
        }
        WKInterfaceDevice.current().play(.click)
    }
    
    func handleFamiliar() {
        scheduler.markFamiliar()
        WKInterfaceDevice.current().play(.success) // 或 .click

        flashFamiliar()
//
//        DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
//            scheduler.commitNext()
//        }
    }

    func handleUnfamiliar() {
        scheduler.markUnfamiliar()
        WKInterfaceDevice.current().play(.click) // 或 .click

        flashUnfamiliar()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
            scheduler.next()
        }
    }


    func flashUnfamiliar() {
        showUnfamiliarFeedback = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            showUnfamiliarFeedback = false
        }
        WKInterfaceDevice.current().play(.click)

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
        
        @AppStorage("learningLanguage") private var languageRaw: String?
        
        var body: some View {
            if languageRaw == nil{
                LanguageSelectView()
            } else {
                MainView()
            }
        }
    }
    
    struct MainView: View {
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
                    let words = WordRepository.loadWords(resourceName: list.resourceName)
                    let scheduler = WordScheduler(words: words)

                    WordPracticeView(
                        scheduler: scheduler,
                        title: list.title
                    )
                }

            }
        }
    }

