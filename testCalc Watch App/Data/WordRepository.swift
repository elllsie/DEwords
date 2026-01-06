import Foundation

struct WordRepository {

    private static func decodeWords(from data: Data) -> [Word]? {
        try? JSONDecoder().decode([Word].self, from: data)
    }

    private static func sanitizeJSONText(_ text: String) -> String {
        var sanitized = text

        // Common data-entry punctuation issues
        sanitized = sanitized
            .replacingOccurrences(of: "，", with: ",")
            .replacingOccurrences(of: "：", with: ":")

        // Remove trailing commas before ']' or '}'
        // Example: { ... , } or [ ... , ]
        if let regex = try? NSRegularExpression(pattern: ",\\s*([\\]}])", options: []) {
            let range = NSRange(sanitized.startIndex..<sanitized.endIndex, in: sanitized)
            sanitized = regex.stringByReplacingMatches(in: sanitized, options: [], range: range, withTemplate: "$1")
        }

        return sanitized
    }

    static func loadWords(resourceName: String) -> [Word] {
        guard
            let url = Bundle.main.url(forResource: resourceName, withExtension: "json"),
            let data = try? Data(contentsOf: url),
            let decoded = decodeWords(from: data)
        else {
            // Fallback: try to load & sanitize text (handles common JSON punctuation issues)
            guard
                let url = Bundle.main.url(forResource: resourceName, withExtension: "json"),
                let rawData = try? Data(contentsOf: url),
                let text = String(data: rawData, encoding: .utf8)
            else {
                return []
            }

            let sanitizedText = sanitizeJSONText(text)
            guard
                let sanitizedData = sanitizedText.data(using: .utf8),
                let decoded = decodeWords(from: sanitizedData)
            else {
                return []
            }

            return decoded
        }

        return decoded
    }

    static let words: [Word] = loadWords(resourceName: "words")
}
