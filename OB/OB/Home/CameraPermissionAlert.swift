// CameraPermissionAlert.swift
// OB App - 相机权限被拒绝时的自定义引导弹窗
// 作者：Louis（iOS 客户端）
// 版本：v1.0 · 2026-04-07

import SwiftUI

// MARK: - CameraPermissionAlert

/// 自定义权限引导弹窗
/// 背景：#E0E0E0 + 高斯模糊（blur radius 20, opacity 0.8）
/// 按钮文字色：#333333
struct CameraPermissionAlert: View {

    /// 点击「取消」的回调
    var onDismiss: () -> Void

    /// 防止「去设置」按钮被快速多次点击
    @State private var isNavigatingToSettings = false

    var body: some View {
        ZStack {
            // 半透明模糊背景（覆盖全屏）
            Color(hex: "#E0E0E0")
                .opacity(0.8)
                .background(.ultraThinMaterial)
                .ignoresSafeArea()

            // 弹窗卡片
            VStack(spacing: 24) {
                // 图标
                Image(systemName: "camera.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(Color(hex: "#333333").opacity(0.6))

                // 文案
                Text("OB 需要授权摄像头权限才能使用")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(Color(hex: "#333333"))
                    .multilineTextAlignment(.center)

                // 按钮组
                VStack(spacing: 12) {
                    // 「去设置」主按钮
                    Button(action: openSettings) {
                        Text("去设置")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                            .background(Color(hex: "#333333"))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .disabled(isNavigatingToSettings)

                    // 「取消」次按钮
                    Button(action: onDismiss) {
                        Text("取消")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(Color(hex: "#333333").opacity(0.6))
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                    }
                }
            }
            .padding(32)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .shadow(color: .black.opacity(0.1), radius: 20, x: 0, y: 4)
            .padding(.horizontal, 40)
        }
    }

    // MARK: - 跳转系统设置

    private func openSettings() {
        guard !isNavigatingToSettings else { return }
        isNavigatingToSettings = true

        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }

        // 延迟重置，防止返回后按钮仍禁用
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            isNavigatingToSettings = false
        }
    }
}
