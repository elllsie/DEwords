import Foundation

struct WordRepository {

    static let words: [Word] = {
        guard
            let url = Bundle.main.url(forResource: "words", withExtension: "json"),
            let data = try? Data(contentsOf: url),
            let decoded = try? JSONDecoder().decode([Word].self, from: data)
        else {
            return []
        }
        return decoded
    }()
}
