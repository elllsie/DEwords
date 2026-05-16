//
//  testCalcApp.swift
//  testCalc Watch App
//
//  Created by 彭滢 on 2026/1/2.
//

import SwiftUI

@main
struct GermanWordWatchApp: App {
    
    init() {
#if DEBUG
        UserDefaults.standard.removeObject(forKey: "learningLanguage")
#endif

        _ = SpeechHelper.shared
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
