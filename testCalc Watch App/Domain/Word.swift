import Foundation

struct Word: Identifiable, Codable {

    let id: String
    let text: String
    let phonetic: String

    // 旧字段（暂时保留，兼容老数据）
    let meaning: String

    // 德语例句
    let example: String

    // 新字段（可选，后面再慢慢补）
    let meaningZh: String?
    let meaningEn: String?

    let exampleZh: String?
    let exampleEn: String?
}

extension Word {

    /// 当前语言下显示的释义
    var displayMeaning: String {
        switch LearningLanguageStore.get() {
        case .en:
            return meaningEn ?? meaning
        default:
            return meaningZh ?? meaning
        }
    }

    /// 当前语言下的例句翻译（暂时可能为空）
    var displayExampleTranslation: String? {
        switch LearningLanguageStore.get() {
        case .en:
            return exampleEn
        default:
            return exampleZh
        }
    }
}
