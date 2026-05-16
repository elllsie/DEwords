import Foundation
import Combine

enum MoveDirection {
    case forward
    case backward
}

final class WordScheduler: ObservableObject {

    // MARK: - 输入
    private let allWords: [Word]
    private let listID: String

    // MARK: - 对外状态
    @Published private(set) var currentWord: Word?
    @Published var moveDirection: MoveDirection = .forward

    // MARK: - 内部状态
    private var currentIndex: Int = 0
    private var reviewQueue: [Word] = []
    private var familiarCounts: [String: Int] = [:]

    // MARK: - Init
    init(words: [Word], listID: String) {
        self.allWords = words
        self.listID = listID

        restoreStateIfNeeded()

        if allWords.isEmpty {
            self.currentIndex = 0
            self.currentWord = nil
            return
        }

        self.currentIndex = min(max(self.currentIndex, 0), allWords.count - 1)
        self.currentWord = allWords[self.currentIndex]
    }

    // MARK: - 导航
    func next() {
        guard !allWords.isEmpty else { return }

        moveDirection = .forward

        if let review = reviewQueue.first {
            reviewQueue.removeFirst()
            currentWord = review
            persistState()
            return
        }

        currentIndex = min(currentIndex + 1, allWords.count - 1)
        currentWord = allWords[currentIndex]
        persistState()
    }

    func previous() {
        guard !allWords.isEmpty else { return }

        moveDirection = .backward

        currentIndex = max(currentIndex - 1, 0)
        currentWord = allWords[currentIndex]
        persistState()
    }

    // MARK: - 标记：熟悉
    func markFamiliar() {
        guard let word = currentWord else { return }

        // ✅ 只记录熟悉次数（给未来用）
        familiarCounts[word.id, default: 0] += 1
        persistState()

        // ✅ 当前 session 只走到下一个词
        next()
    }

    // MARK: - 标记：不熟
    func markUnfamiliar() {
        guard let word = currentWord else { return }

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            // 插在队列最前面，确保优先
            self.reviewQueue.insert(word, at: 0)
            self.persistState()
        }
    }

    private func restoreStateIfNeeded() {
        guard
            let state = LearningProgressStore.load(listID: listID),
            !allWords.isEmpty
        else {
            currentIndex = 0
            reviewQueue = []
            familiarCounts = [:]
            return
        }

        currentIndex = min(max(state.currentIndex, 0), allWords.count - 1)

        let wordsByID = allWords.reduce(into: [String: Word]()) { result, word in
            if result[word.id] == nil {
                result[word.id] = word
            }
        }

        reviewQueue = state.reviewQueueWordIDs.compactMap { wordsByID[$0] }
        familiarCounts = state.familiarCounts
    }

    private func persistState() {
        let state = LearningSessionState(
            currentIndex: currentIndex,
            reviewQueueWordIDs: reviewQueue.map(\.id),
            familiarCounts: familiarCounts
        )
        LearningProgressStore.save(state, listID: listID)
    }
}
