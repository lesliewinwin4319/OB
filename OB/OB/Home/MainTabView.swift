// MainTabView.swift
// OB App - 主导航容器：管理相机与朋友圈的左右滑动切换
// 作者：Louis（iOS 客户端）
// 版本：v1.0 · 2026-04-09

import SwiftUI

// MARK: - MainTab Enum

enum MainTab: Int, CaseIterable {
    case camera = 0
    case feed = 1
    
    var title: String {
        switch self {
        case .camera: return "相机"
        case .feed: return "朋友圈"
        }
    }
}

// MARK: - MainTabView

struct MainTabView: View {
    @EnvironmentObject var authManager: AuthStateManager
    @StateObject private var feedViewModel = FeedViewModel()

    /// 当前选中的 Tab
    @State private var selectedTab: MainTab = .camera

    /// 根据当前 Tab 决定 UI 元素颜色：相机页为白色，朋友圈页为深色
    private var uiColor: Color {
        selectedTab == .camera ? .white : Color(hex: "#1A1A1A")
    }

    /// 他人页：非空时从右侧滑入覆盖所有层
    @State private var profileUser: Post.User? = nil

    var body: some View {
        ZStack {
            // ── 主界面 ──
            ZStack(alignment: .top) {
                TabView(selection: $selectedTab) {
                    HomeView()
                        .tag(MainTab.camera)
                    FeedView(
                        viewModel: feedViewModel,
                        onNavigateToProfile: { user in
                            withAnimation(.easeInOut(duration: 0.28)) {
                                profileUser = user
                            }
                        }
                    )
                    .tag(MainTab.feed)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .ignoresSafeArea()
                .safeAreaInset(edge: .bottom, spacing: 0) {
                    customTabBar
                }

                // 顶部全宽 Bar 叠在最上层
                TopNavigationBar(
                    selectedTab: selectedTab,
                    onTabTapped: { _ in
                        ToastManager.shared.show("功能开发中，敬请期待")
                    }
                )
            }

            // ── 他人页 overlay：从右侧滑入，完整覆盖 TopBar 和 TabBar ──
            if let user = profileUser {
                ProfilePlaceholderView(
                    user: user,
                    onDismiss: {
                        withAnimation(.easeInOut(duration: 0.28)) {
                            profileUser = nil
                        }
                    }
                )
                .transition(.move(edge: .trailing))
                .zIndex(10)
            }
        }
    }

    // MARK: - Custom Tab Bar（全宽固定底部，不悬浮）

    private var customTabBar: some View {
        HStack(spacing: 0) {
            ForEach(MainTab.allCases, id: \.self) { tab in
                Button(action: {
                    if selectedTab == .feed && tab == .feed {
                        Task {
                            await feedViewModel.refresh()
                            feedViewModel.scrollToTop()
                        }
                    }
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedTab = tab
                    }
                }) {
                    VStack(spacing: 4) {
                        Text(tab.title)
                            .font(.system(size: 16, weight: selectedTab == tab ? .bold : .medium))
                            .foregroundStyle(uiColor.opacity(selectedTab == tab ? 1.0 : 0.5))

                        // 选中指示器（小横杠）
                        if selectedTab == tab {
                            Capsule()
                                .fill(uiColor)
                                .frame(width: 16, height: 2)
                                .transition(.scale.combined(with: .opacity))
                        } else {
                            Capsule()
                                .fill(Color.clear)
                                .frame(width: 16, height: 2)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                }
            }
        }
        // 全宽背景：相机页半透明，朋友圈页纯白
        .background(
            Group {
                if selectedTab == .camera {
                    Color.black.opacity(0.35)
                } else {
                    Color.white
                }
            }
            .ignoresSafeArea(edges: .bottom)
            .animation(.easeInOut(duration: 0.25), value: selectedTab)
        )
        .animation(.easeInOut(duration: 0.2), value: selectedTab)
    }
}

// MARK: - Preview

#Preview {
    MainTabView()
        .environmentObject(AuthStateManager())
}
