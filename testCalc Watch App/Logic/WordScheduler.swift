import Foundation
import Combine

final class WordScheduler: ObservableObject {

    // MARK: - 输入
    private let allWords: [Word]

    // MARK: - 对外状态
    @Published private(set) var currentWord: Word?

    // MARK: - 内部状态
    private var currentIndex: Int = 0
    private var reviewQueue: [Word] = []
    private var familiarCounts: [String: Int] = [:]

    // MARK: - Init
    init(words: [Word]) {
        self.allWords = words
        self.currentIndex = 0
        self.currentWord = words.first
    }

    // MARK: - 下一个
    func next() {
        guard !allWords.isEmpty else { return }

        // ① 优先处理“不熟复习队列”
        if !reviewQueue.isEmpty {
            currentWord = reviewQueue.removeFirst()
            return
        }

        // ② 正常顺序往下走
        currentIndex = (currentIndex + 1) % allWords.count
        currentWord = allWords[currentIndex]
    }

    // MARK: - 上一个（仅用于手动回看）
    func previous() {
        guard !allWords.isEmpty else { return }

        currentIndex = max(currentIndex - 1, 0)
        currentWord = allWords[currentIndex]
    }

    // MARK: - 标记：熟悉
    func markFamiliar() {
        guard let word = currentWord else { return }

        // ✅ 只记录熟悉次数（给未来用）
        familiarCounts[word.id, default: 0] += 1

        // ✅ 当前 session 只走到下一个词
        next()
    }

    // MARK: - 标记：不熟
//    func markUnfamiliar() {
//        guard let word = currentWord else { return }
//
//        // ✅ 插入到短期复习队列（马上或很快再见）
//        reviewQueue.append(word)
//
//        // ✅ 当前 session 继续往下
//        next()
//    }
    func markUnfamiliar() {
        guard let word = currentWord else { return }

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            // 插在队列最前面，确保优先
            self.reviewQueue.insert(word, at: 0)
        }
    }

}
