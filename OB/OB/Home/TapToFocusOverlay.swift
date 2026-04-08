// TapToFocusOverlay.swift
// OB App - 点击对焦交互层：黄色方框动画 + 震动反馈
// 作者：Louis（iOS 客户端）
// 版本：v1.0 · 2026-04-07

import SwiftUI

// MARK: - TapToFocusOverlay

/// 覆盖在相机预览之上的对焦交互层
/// 点击后在该位置展示黄色方框（#E2C94C），缩小后淡出消失，同时触发轻震动
struct TapToFocusOverlay: View {

    /// 对焦回调：传递归一化坐标（0~1）给 CameraManager
    var onFocus: (CGPoint) -> Void

    /// 当前对焦方框位置（屏幕坐标）
    @State private var focusPoint: CGPoint? = nil

    /// 方框缩放比例
    @State private var focusScale: CGFloat = 1.0

    /// 方框透明度
    @State private var focusOpacity: Double = 1.0

    /// 当前对焦 ID，用于取消上一次动画
    @State private var focusID: UUID = UUID()

    private let feedbackGenerator = UIImpactFeedbackGenerator(style: .light)

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // 透明触摸区域
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture { location in
                        handleTap(at: location, in: geometry.size)
                    }

                // 对焦方框
                if let point = focusPoint {
                    RoundedRectangle(cornerRadius: 2)
                        .stroke(Color(hex: "#E2C94C"), lineWidth: 1)
                        .frame(width: 70, height: 70)
                        .scaleEffect(focusScale)
                        .opacity(focusOpacity)
                        .position(point)
                        .allowsHitTesting(false) // 方框不拦截触摸
                }
            }
        }
    }

    // MARK: - 处理点击

    private func handleTap(at location: CGPoint, in size: CGSize) {
        // 触发震动反馈
        feedbackGenerator.impactOccurred()

        // 设置新的对焦位置，重置动画状态
        let currentID = UUID()
        focusID = currentID
        focusPoint = location
        focusScale = 1.0
        focusOpacity = 1.0

        // 计算归一化坐标传给 CameraManager
        // 注意：AVCaptureDevice 的坐标系是横向的，x/y 需要翻转
        let normalizedX = location.y / size.height
        let normalizedY = 1.0 - (location.x / size.width)
        onFocus(CGPoint(x: normalizedX, y: normalizedY))

        // 动画阶段 1：缩小到 0.7（0.3s）
        withAnimation(.easeInOut(duration: 0.3)) {
            focusScale = 0.7
        }

        // 动画阶段 2：淡出消失（0.2s，延迟 0.3s 后开始）
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            guard self.focusID == currentID else { return } // 被新点击取代则不执行
            withAnimation(.easeOut(duration: 0.2)) {
                focusOpacity = 0
            }
        }

        // 完全消失后清除位置
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            guard self.focusID == currentID else { return }
            focusPoint = nil
        }
    }
}
