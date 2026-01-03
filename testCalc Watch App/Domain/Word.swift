import Foundation

struct Word: Identifiable, Codable {
    let id: String
    let text: String
    let phonetic: String
    let meaning: String
    let example: String
}
