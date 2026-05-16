import Foundation

struct LearningSessionState: Codable {
	var currentIndex: Int
	var reviewQueueWordIDs: [String]
	var familiarCounts: [String: Int]

	static let initial = LearningSessionState(
		currentIndex: 0,
		reviewQueueWordIDs: [],
		familiarCounts: [:]
	)
}

enum LearningProgressStore {
	private static let keyPrefix = "learningProgress."

	private static func key(for listID: String) -> String {
		"\(keyPrefix)\(listID)"
	}

	static func load(listID: String) -> LearningSessionState? {
		let storageKey = key(for: listID)
		guard
			let data = UserDefaults.standard.data(forKey: storageKey),
			let state = try? JSONDecoder().decode(LearningSessionState.self, from: data)
		else {
			return nil
		}
		return state
	}

	static func save(_ state: LearningSessionState, listID: String) {
		let storageKey = key(for: listID)
		guard let data = try? JSONEncoder().encode(state) else { return }
		UserDefaults.standard.set(data, forKey: storageKey)
	}

	static func clear(listID: String) {
		UserDefaults.standard.removeObject(forKey: key(for: listID))
	}
}
