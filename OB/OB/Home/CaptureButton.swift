// CaptureButton.swift
// OB App - 拍照按钮：触发拍照回调，拍照中禁用
// 作者：Louis（iOS 客户端）
// 版本：v1.1 · 2026-04-08（接入拍照回调 + 防抖）

import SwiftUI

// MARK: - CaptureButton

/// 底部拍照按钮
/// 外圈 #D6D6D6（直径 72pt），内圈 #FFFFFF（直径 60pt）
/// 未授权或拍照中时 alpha 0.3 + 不可点击
struct CaptureButton: View {

    /// 是否启用（权限授权后为 true）
    let isEnabled: Bool

    /// 是否正在拍照（快门防抖）
    var isCapturing: Bool = false

    /// 拍照回调
    var onCapture: (() -> Void)? = nil

    /// 按下缩放动画
    @State private var isPressed = false

    /// 按钮是否可交互
    private var canTap: Bool {
        isEnabled && !isCapturing
    }

    var body: some View {
        Button(action: handleTap) {
            ZStack {
                // 外圈
                Circle()
                    .fill(Color(hex: "#D6D6D6"))
                    .frame(width: 72, height: 72)

                // 内圈
                Circle()
                    .fill(Color(hex: "#FFFFFF"))
                    .frame(width: 60, height: 60)
            }
            .scaleEffect(isPressed ? 0.92 : 1.0)
        }
        .buttonStyle(.plain) // 去掉系统默认高亮效果
        .opacity(canTap ? 1.0 : 0.3)
        .disabled(!canTap)
        .animation(.easeInOut(duration: 0.1), value: isPressed)
    }

    // MARK: - 点击处理

    private func handleTap() {
        guard canTap else { return }

        // 轻微缩放动画反馈
        isPressed = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            isPressed = false
        }

        // 触发拍照回调
        onCapture?()
    }
}
