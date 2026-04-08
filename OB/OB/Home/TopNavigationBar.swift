// TopNavigationBar.swift
// OB App - 首页顶部导航栏（三个 Tab 入口，SF Symbols 占位）
// 作者：Louis（iOS 客户端）
// 版本：v1.0 · 2026-04-07

import SwiftUI

// MARK: - TopNavigationBar

/// 首页顶部导航栏
/// 布局：左上「我」/ 右上「朋友」
/// 底部 Tab Bar 区域的「朋友圈」由 HomeView 的 bottomBar 部分处理
struct TopNavigationBar: View {

    /// 点击入口的回调（统一弹 Toast）
    var onTabTapped: (String) -> Void

    var body: some View {
        HStack {
            // 左侧：「我」入口
            Button(action: { onTabTapped("我") }) {
                Image(systemName: "person.crop.circle")
                    .font(.system(size: 26, weight: .regular))
                    .foregroundStyle(.white)
            }

            Spacer()

            // 右侧：「朋友」入口
            Button(action: { onTabTapped("朋友") }) {
                Image(systemName: "person.2.fill")
                    .font(.system(size: 22, weight: .regular))
                    .foregroundStyle(.white)
            }
        }
        .padding(.horizontal, 20)
    }
}
