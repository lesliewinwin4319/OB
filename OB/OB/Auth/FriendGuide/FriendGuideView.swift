// FriendGuideView.swift
// OB App - 好友引导页
// 作者：Louis（iOS 客户端）
// 版本：v1.0 · 2026-04-04

import SwiftUI

// MARK: - 好友申请数据模型（占位结构）

/// 好友申请条目，当前字段为空态占位，后续由产品补充接口逻辑
struct FriendRequest: Identifiable {
    let id: String
    let avatarURL: String?
    let nickname: String
}

// MARK: - FriendGuideView

struct FriendGuideView: View {
    @EnvironmentObject var authManager: AuthStateManager

    // 微信加好友 Toast 控制
    @State private var showWeChatInviteToast = false

    // TODO: 待产品确认 — 好友申请列表由服务端接口提供，当前为空态占位
    // 接口：GET /friend/requests  返回 FriendRequest 数组
    @State private var friendRequests: [FriendRequest] = [
        FriendRequest(id: "mock_1", avatarURL: nil, nickname: "杰哥"),
        FriendRequest(id: "mock_2", avatarURL: nil, nickname: "杰哥")
    ]

    var body: some View {
        ZStack {
            Color(hex: "#FAFAFA").ignoresSafeArea()

            VStack(spacing: 0) {
                // 页面标题
                pageTitle
                    .padding(.top, 56)
                    .padding(.bottom, 32)

                // 第一部分：微信邀请入口
                wechatInviteSection
                    .padding(.horizontal, 24)

                Divider()
                    .padding(.horizontal, 24)
                    .padding(.vertical, 24)

                // 第二部分：好友申请列表
                friendRequestSection
                    .padding(.horizontal, 24)

                Spacer()

                // 下一步进首页（直接可点，无前置条件）
                enterHomeButton
                    .padding(.horizontal, 24)
                    .padding(.bottom, 48)
            }

            // Toast 覆盖
            if showWeChatInviteToast {
                wechatToastView
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
                    .animation(.easeInOut(duration: 0.2), value: showWeChatInviteToast)
            }
        }
        // 禁用导航栏返回按钮（见 PRD §3 导航约束）
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        // 禁用侧滑返回手势（见技术方案 §3.3）
        .onAppear {
            disableInteractivePopGesture()
        }
        .onDisappear {
            // 理论上不会触发（进首页后整个 NavigationStack 被替换），作为保护性恢复
            enableInteractivePopGesture()
        }
    }

    // MARK: - 页面标题

    private var pageTitle: some View {
        VStack(spacing: 6) {
            Text("认识一下")
                .font(.system(size: 26, weight: .bold))
                .foregroundStyle(.primary)
            // TODO: 待产品确认 — 好友引导页副标题文案
            Text("看看有没有你认识的人")
                .font(.system(size: 14))
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - 微信邀请区

    private var wechatInviteSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("邀请微信好友")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.primary)
                Text("让朋友们也来 OB")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button(action: handleWeChatInvite) {
                HStack(spacing: 6) {
                    // TODO: 替换为微信官方 Logo
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 14, weight: .semibold))
                    Text("邀请")
                        .font(.system(size: 15, weight: .semibold))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 9)
                .background(Color(hex: "#1AAD19"))
                .clipShape(Capsule())
            }
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 20)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2)
    }

    // MARK: - 好友申请列表区

    private var friendRequestSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("好友申请")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.primary)

            if friendRequests.isEmpty {
                // 空态展示
                emptyFriendRequestView
            } else {
                // 申请列表
                ForEach(friendRequests) { request in
                    FriendRequestRow(request: request)
                }
            }
        }
    }

    // MARK: - 好友申请空态

    private var emptyFriendRequestView: some View {
        VStack(spacing: 12) {
            // TODO: 待产品确认 — 需要 LESLIE 提供空态占位图，当前用 SF Symbol 代替
            Image(systemName: "person.2.slash")
                .font(.system(size: 44))
                .foregroundStyle(Color.secondary.opacity(0.4))
            Text("暂时没有好友申请")
                .font(.system(size: 14))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
    }

    // MARK: - 下一步进首页按钮

    private var enterHomeButton: some View {
        Button(action: handleEnterHome) {
            Text("进入 OB")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(Color(hex: "#1AAD19"))
                .clipShape(RoundedRectangle(cornerRadius: 14))
        }
    }

    // MARK: - 微信邀请 Toast

    private var wechatToastView: some View {
        VStack {
            Spacer()
            Text("功能开发中，敬请期待")
                .font(.system(size: 14))
                .foregroundStyle(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(Color.black.opacity(0.72))
                .clipShape(Capsule())
                .padding(.bottom, 80)
        }
    }

    // MARK: - 业务逻辑

    /// 点击微信加好友按钮（当前为 Toast 占位）
    private func handleWeChatInvite() {
        showWeChatInviteToast = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            showWeChatInviteToast = false
        }
    }

    /// 点击进入首页
    private func handleEnterHome() {
        // 状态已在资料页提交时设为 active，此处仅触发导航刷新
        // 若因异常状态未更新，强制再次转移确保能进首页
        if authManager.registrationStep != .active {
            authManager.transition(to: .active)
        }
        // RootView 监听到 registrationStep == .active 后会自动切换到 HomeView
    }

    // MARK: - 侧滑手势控制

    private func disableInteractivePopGesture() {
        if let navController = UIApplication.shared.topNavigationController {
            navController.interactivePopGestureRecognizer?.isEnabled = false
        }
    }

    private func enableInteractivePopGesture() {
        if let navController = UIApplication.shared.topNavigationController {
            navController.interactivePopGestureRecognizer?.isEnabled = true
        }
    }
}

// MARK: - FriendRequestRow

/// 好友申请列表行
struct FriendRequestRow: View {
    let request: FriendRequest

    // TODO: 待产品确认 — 同意按钮点击后调用接口 POST /friend/accept，接口文档待补充
    @State private var isAccepted = false

    var body: some View {
        HStack(spacing: 12) {
            // 头像
            AvatarView(
                imageURL: request.avatarURL,
                name: request.nickname,
                backgroundColor: MorandiPalette.random(),
                size: 48
            )

            // 昵称
            Text(request.nickname)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(.primary)

            Spacer()

            // 同意按钮
            if isAccepted {
                Text("已同意")
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
            } else {
                Button("同意") {
                    // TODO: 调用服务端接口 POST /friend/accept，参数 { "requestId": request.id }
                    isAccepted = true
                }
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 7)
                .background(Color(hex: "#1AAD19"))
                .clipShape(Capsule())
            }
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        FriendGuideView()
            .environmentObject(AuthStateManager())
    }
}
