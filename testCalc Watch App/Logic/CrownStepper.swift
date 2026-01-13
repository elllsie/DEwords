//
//  CrownStepper.swift
//  testCalc
//
//  Created by 彭滢 on 2026/1/13.
//

import SwiftUI
import WatchKit
struct CrownStepper: ViewModifier {

    let threshold: Double
    let onStepForward: () -> Void
    let onStepBackward: () -> Void

    @Binding var crownValue: Double
    @State private var accumulated: Double = 0

    let by: Double

    func body(content: Content) -> some View {
        content
            .digitalCrownRotation(
                $crownValue,
                from: -1000,
                through: 1000,
                by: by,
                sensitivity: .medium,
                isContinuous: true,
                isHapticFeedbackEnabled: false // 自行控制卡塔触觉
            )
            .onChange(of: crownValue) { oldValue, newValue in
                let delta = newValue - oldValue
                accumulated += delta

                // 小齿轻微反馈
                if abs(delta) >= 1 {
                    WKInterfaceDevice.current().play(.directionUp) // 或 directionDown，轻微触感
                }

                // 阈值触发切换
                if accumulated >= threshold {
                    onStepForward()
                    accumulated = 0
                    WKInterfaceDevice.current().play(.click) // 清脆卡塔
                } else if accumulated <= -threshold {
                    onStepBackward()
                    accumulated = 0
                    WKInterfaceDevice.current().play(.click)
                }
            }
    }
}

extension View {
    func crownStepper(
        crownValue: Binding<Double>,
        threshold: Double = 7,
        by: Double = 1,
        onStepForward: @escaping () -> Void,
        onStepBackward: @escaping () -> Void
    ) -> some View {
        self.modifier(
            CrownStepper(
                threshold: threshold,
                onStepForward: onStepForward,
                onStepBackward: onStepBackward,
                crownValue: crownValue,
                by: by
            )
        )
    }
}
