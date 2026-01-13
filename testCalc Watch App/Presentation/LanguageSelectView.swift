import SwiftUI

struct LanguageSelectView: View {

    @AppStorage("learningLanguage") private var languageRaw: String?

    var body: some View {
        VStack(spacing: 12) {


            Button("中文学德语") {
                languageRaw = "zh"
            }

            Button("Learn German in English") {
                languageRaw = "en"
            }
        }
    }
}
