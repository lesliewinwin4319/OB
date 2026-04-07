// RootView.swift
// OB App - 根视图：监听 AuthStateManager 做全局路由决策
// 作者：Louis（iOS 客户端）
// 版本：v1.0 · 2026-04-04

import SwiftUI

// MARK: - RootView

/// App 最顶层视图，以 authManager.registrationStep 为唯一路由依据
/// 不参与任何业务渲染，只做"哪棵视图树当前可见"的决策
struct RootView: View {
    @StateObject private var authManager = AuthStateManager()

    var body: some View {
        Group {
            switch authManager.registrationStep {
            case .unknown:
                // App 启动时尚未确认状态，展示 Loading 避免页面闪烁
                loadingView

            case .login:
                // 未登录：展示登录页
                LoginView()
                    .environmentObject(authManager)

            case .pendingProfile:
                // 已授权但资料未完善：进入注册流程
                AuthFlowView()
                    .environmentObject(authManager)

            case .active:
                // 资料完善：进首页，完全脱离注册流程
                HomeView()
                    .environmentObject(authManager)
            }
        }
        .onAppear {
            // App 启动后立即从服务端同步最新状态（本地 UserDefaults 仅作冷启动过渡用）
            syncStatusFromServer()
        }
    }

    // MARK: - Loading 视图

    private var loadingView: some View {
        ZStack {
            Color(hex: "#FAFAFA").ignoresSafeArea()
            ProgressView()
                .scaleEffect(1.2)
                .tint(Color(hex: "#B5C0D0"))
        }
    }

    // MARK: - 服务端状态同步

    /// App 启动时调用，从服务端拉取最新用户状态
    private func syncStatusFromServer() {
        // TODO: 实现服务端状态同步
        // 接口：GET /user/me（需要带 JWT token in header）
        // 成功响应体示例：{ "status": "PENDING_PROFILE" | "ACTIVE" }
        //
        // 示例调用：
        //   APIClient.shared.fetchUserStatus { result in
        //       switch result {
        //       case .success(let status):
        //           authManager.syncFromServer(status: status)
        //       case .failure:
        //           // 网络异常：保留本地 UserDefaults 缓存状态，Loading → 已知上次状态
        //           // 若本地无缓存（首次安装），默认为 .login
        //           if authManager.registrationStep == .unknown {
        //               authManager.transition(to: .login)
        //           }
        //       }
        //   }
        //
        // 当前开发阶段：直接用本地缓存（restore() 已在 AuthStateManager.init() 中调用）
        // 若本地仍为 .unknown，兜底为 .login
        if authManager.registrationStep == .unknown {
            authManager.transition(to: .login)
        }
    }
}

// MARK: - AuthFlowView

/// 注册流程容器，包含 ProfileSetupView → FriendGuideView 的 NavigationStack
/// 与 LoginView 分离，使得两者可以独立管理导航栈
struct AuthFlowView: View {
    @EnvironmentObject var authManager: AuthStateManager

    // NavigationStack 路径：pendingProfile 状态进来时默认在资料页
    @State private var navigationPath = NavigationPath()

    var body: some View {
        NavigationStack(path: $navigationPath) {
            ProfileSetupView()
                .environmentObject(authManager)
                .navigationDestination(for: String.self) { destination in
                    if destination == "friendGuide" {
                        FriendGuideView()
                            .environmentObject(authManager)
                    }
                }
        }
        .onChange(of: authManager.registrationStep) { newStep in
            // 资料填写完成（服务端确认后）自动推入好友引导页
            // 注意：此处监听状态变化来驱动导航，避免在 ProfileSetupView 内直接 push
            // TODO: 待产品确认 — 资料提交成功后的导航时机是否需要调整
            // 当前逻辑：status 变为 active 时先推好友引导页，好友引导页再进首页
            if newStep == .active && navigationPath.isEmpty {
                navigationPath.append("friendGuide")
                // 同时将状态临时回退为 pendingProfile，防止 RootView 直接跳首页
                // 真正进首页的时机在 FriendGuideView 的"进入 OB"按钮
                // TODO: 待产品确认 — 此处状态流转逻辑需与后端对齐
                //
                // 注意：这里有一个设计权衡点：
                // 方案 A（当前）：status 在提交资料时即改为 ACTIVE，好友引导页不阻塞进首页
                // 方案 B：引入中间状态 PENDING_FRIEND，好友引导页完成后才改为 ACTIVE
                // 推荐方案 B，但需等服务端确认
            }
        }
    }
}

// MARK: - HomeView（占位）

/// 首页占位视图，待正式首页模块实现后替换
struct HomeView: View {
    @EnvironmentObject var authManager: AuthStateManager

    var body: some View {
        ZStack {
            Color(hex: "#F5E8DD").opacity(0.3).ignoresSafeArea()
            VStack(spacing: 20) {
                Text("🎉 欢迎来到 OB")
                    .font(.system(size: 24, weight: .bold))
                // TODO: 替换为正式首页内容
                Text("首页开发中")
                    .foregroundStyle(.secondary)

                Button("退出登录（测试用）") {
                    authManager.logout()
                }
                .font(.system(size: 14))
                .foregroundStyle(.secondary)
            }
        }
        .navigationBarBackButtonHidden(true)
    }
}

// MARK: - App 入口

/// 将 RootView 接入 App 入口（实际项目在 OBApp.swift 中配置，这里仅供参考）
/*
@main
struct OBApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
        }
    }
}
*/

// MARK: - Preview

#Preview("登录页") {
    let manager = AuthStateManager()
    manager.transition(to: .login)
    return RootView()
}

#Preview("资料填写页") {
    let manager = AuthStateManager()
    manager.wechatUserInfo = WeChatUserInfo(openid: "mock", nickname: "杰哥", avatarURL: nil)
    manager.transition(to: .pendingProfile)
    return AuthFlowView().environmentObject(manager)
}
