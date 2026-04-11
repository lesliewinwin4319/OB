// ProfileSetupView.swift
// OB App - 资料填写页（含 ProfileSetupViewModel）
// 作者：Louis（iOS 客户端）
// 版本：v1.0 · 2026-04-04

import SwiftUI

// MARK: - ProfileSetupViewModel

@Observable
final class ProfileSetupViewModel {

    // MARK: 状态

    var nickname: String = ""
    var avatarBgColor: Color         // 进入页面时随机固定，此后不再改变
    var showLengthToast: Bool = false
    var errorMessage: String? = nil

    // MARK: 常量

    /// 昵称字符上限（已与服务端对齐，统一为 20 字符）
    static let maxNicknameLength = 20

    // MARK: 计算属性

    /// 是否允许点击下一步：输入框非空
    var isNextEnabled: Bool {
        !nickname.isEmpty
    }

    // MARK: Init

    init() {
        // 进入页面时随机选取莫兰迪背景色，之后固定不再变（即使昵称实时更新）
        avatarBgColor = MorandiPalette.random()
    }

    // MARK: - 输入处理

    /// 监听昵称输入，超出上限时截断并触发 Toast
    /// 需在 View 的 .onChange(of: viewModel.nickname) 中调用
    func handleNicknameChange(_ newValue: String) {
        if newValue.count > Self.maxNicknameLength {
            // 使用 prefix 确保 Emoji / 中文等多字节字符不会被切坏
            nickname = String(newValue.prefix(Self.maxNicknameLength))
            triggerLengthToast()
        }
    }

    // MARK: - Toast 控制

    private func triggerLengthToast() {
        showLengthToast = true
        // Toast 展示 1.5 秒后自动消失
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            self?.showLengthToast = false
        }
    }
}

// MARK: - ProfileSetupView

struct ProfileSetupView: View {
    @EnvironmentObject var authManager: AuthStateManager
    @State private var viewModel = ProfileSetupViewModel()

    /// 键盘焦点控制：页面进入时自动拉起键盘
    @FocusState private var isNicknameFieldFocused: Bool

    /// submit 成功后的导航回调，由父级 AuthFlowView 传入；Preview 不传时默认 nil
    var onProfileCompleted: (() -> Void)? = nil

    var body: some View {
        ZStack {
            // 背景色与登录页保持一致
            Color(hex: "#FAFAFA").ignoresSafeArea()

            VStack(spacing: 0) {
                // 顶部文案（PRD 指定原文）
                headerSection
                    .padding(.top, 56)

                // 动态头像预览
                avatarSection
                    .padding(.top, 40)

                // 昵称输入框
                nicknameField
                    .padding(.top, 32)
                    .padding(.horizontal, 24)

                // 字符计数提示
                charCountHint
                    .padding(.top, 8)
                    .padding(.horizontal, 24)

                Spacer()

                // 下一步按钮
                nextStepButton
                    .padding(.horizontal, 24)
                    .padding(.bottom, 48)
            }

            // Toast 覆盖层
            if viewModel.showLengthToast {
                toastView
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
                    .animation(.easeInOut(duration: 0.2), value: viewModel.showLengthToast)
            }
        }
        .navigationBarBackButtonHidden(true)  // 资料页无返回入口（UID 已创建）
        // TODO: 待产品确认 — 是否需要导航栏标题，当前隐藏
        .toolbar(.hidden, for: .navigationBar)
        .onAppear {
            // 预填微信昵称（若获取失败则保持空，见 PRD §1 异常处理）
            if let wechatNickname = authManager.wechatUserInfo?.nickname {
                viewModel.nickname = String(wechatNickname.prefix(ProfileSetupViewModel.maxNicknameLength))
            }
            // 延迟 0.1s 触发键盘聚焦，与页面进场动画结束时机对齐（见技术方案 §4 风险说明）
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isNicknameFieldFocused = true
            }
        }
    }

    // MARK: - 顶部文案

    private var headerSection: some View {
        VStack(spacing: 8) {
            Text("用真实的名字可以方便朋友找到你")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(.primary)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 32)
    }

    // MARK: - 头像区

    private var avatarSection: some View {
        AvatarView(
            imageURL: authManager.wechatUserInfo?.avatarURL,
            name: viewModel.nickname,
            backgroundColor: viewModel.avatarBgColor,
            size: 96
        )
    }

    // MARK: - 昵称输入框

    private var nicknameField: some View {
        TextField("输入你的昵称", text: $viewModel.nickname)
            .font(.system(size: 17))
            .multilineTextAlignment(.center)
            .focused($isNicknameFieldFocused)
            // 键盘右下角「确认/发送」键触发与下一步按钮相同的逻辑
            .submitLabel(.done)
            .onSubmit {
                handleNextStep()
            }
            .onChange(of: viewModel.nickname) { _, newValue in
                viewModel.handleNicknameChange(newValue)
            }
            .padding(.vertical, 14)
            .padding(.horizontal, 16)
            .background(Color(hex: "#F2F2F7"))
            .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - 字符计数提示

    private var charCountHint: some View {
        HStack {
            Spacer()
            Text("\(viewModel.nickname.count) / \(ProfileSetupViewModel.maxNicknameLength)")
                .font(.system(size: 12))
                .foregroundStyle(
                    viewModel.nickname.count >= ProfileSetupViewModel.maxNicknameLength
                        ? Color.red.opacity(0.7)
                        : Color.secondary.opacity(0.6)
                )
        }
    }

    // MARK: - 下一步按钮

    private var nextStepButton: some View {
        Button(action: handleNextStep) {
            Text("下一步")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(
                    // 输入框为空时置灰禁用（见 PRD §2）
                    viewModel.isNextEnabled
                        ? Color(hex: "#1AAD19")
                        : Color(hex: "#C7C7CC")
                )
                .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .disabled(!viewModel.isNextEnabled)
        .animation(.easeInOut(duration: 0.15), value: viewModel.isNextEnabled)
    }

    // MARK: - Toast 视图

    private var toastView: some View {
        VStack {
            Spacer()
            Text("昵称最多 \(ProfileSetupViewModel.maxNicknameLength) 个字符")
                .font(.system(size: 14))
                .foregroundStyle(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(Color.black.opacity(0.72))
                .clipShape(Capsule())
                .padding(.bottom, 120)  // 悬浮在键盘上方
        }
    }

    // MARK: - 下一步业务逻辑

    private func handleNextStep() {
        guard viewModel.isNextEnabled else { return }
        isNicknameFieldFocused = false

        Task {
            do {
                try await authManager.submitProfile(
                    nickname: viewModel.nickname,
                    avatarWxUrl: authManager.wechatUserInfo?.avatarURL
                )
                // 持久化 active 状态，防止断网强退后回到填写页
                authManager.markProfileCompleted()
                onProfileCompleted?()
            } catch let error as APIError {
                viewModel.errorMessage = error.message
            } catch {
                viewModel.errorMessage = "提交失败，请重试"
            }
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        ProfileSetupView()
            .environmentObject({
                let manager = AuthStateManager()
                manager.wechatUserInfo = WeChatUserInfo(
                    openid: "mock",
                    nickname: "杰哥",
                    avatarURL: nil
                )
                manager.registrationStep = .pendingProfile
                return manager
            }())
    }
}
