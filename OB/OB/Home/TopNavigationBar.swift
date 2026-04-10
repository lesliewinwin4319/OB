// TopNavigationBar.swift
// OB App - 首页顶部全宽导航栏
// 作者：Louis（iOS 客户端）
// 版本：v1.1 · 2026-04-10

import SwiftUI

// MARK: - TopNavigationBar

/// 全宽顶部导航栏，与底部 TabBar 对称
/// 布局：左「我」/ 中「OB」/ 右「朋友」
/// 相机页：半透明黑底 + 白色文字；朋友圈页：纯白底 + 深色文字
struct TopNavigationBar: View {

    var selectedTab: MainTab
    var onTabTapped: (String) -> Void

    private var textColor: Color {
        selectedTab == .camera ? .white : Color(hex: "#1A1A1A")
    }

    var body: some View {
        HStack(spacing: 0) {
            // 左：「我」
            Button(action: { onTabTapped("我") }) {
                Text("我")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(textColor)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            }

            // 中：OB 品牌标题
            Text("OB")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(textColor)
                .frame(maxWidth: .infinity)

            // 右：「朋友」
            Button(action: { onTabTapped("朋友") }) {
                Text("朋友")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(textColor)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            }
        }
        // 背景延伸到状态栏（safe area 顶部）
        .background(
            Group {
                if selectedTab == .camera {
                    Color.black.opacity(0.35)
                } else {
                    Color.white
                }
            }
            .ignoresSafeArea(edges: .top)
            .animation(.easeInOut(duration: 0.25), value: selectedTab)
        )
        .animation(.easeInOut(duration: 0.25), value: selectedTab)
    }
}
