//
//  SpacingEngine.swift
//  testCalc
//
//  Created by 彭滢 on 2026/1/4.
//

import Foundation

struct SpacingEngine {

    static func nextIndex(
        totalWords: Int,
        currentIndex: Int,
        familiarCount: Int
    ) -> Int {

        // familiarCount: 1 => 第一次熟悉（2%）；之后每次间隔 ×2
        let k = max(familiarCount, 1)

        let rawGap = Double(totalWords) * (0.02 * pow(2.0, Double(k - 1)))
        let cappedGap = min(rawGap, Double(totalWords) * 0.6)

        let gap = Int(round(cappedGap))

        return currentIndex + max(gap, 1)
    }
}
