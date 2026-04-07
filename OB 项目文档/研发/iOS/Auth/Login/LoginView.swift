// LoginView.swift
// OB App - 登录页
// 作者：Louis（iOS 客户端）
// 版本：v1.0 · 2026-04-04

import SwiftUI

// MARK: - LoginView

struct LoginView: View {
    @EnvironmentObject var authManager: AuthStateManager

    // Sheet 展示控制
    @State private var showUserAgreement = false
    @State private var showPrivacyPolicy = false

    // 微信未安装时的 Alert
    @State private var showWeChatNotInstalledAlert = false

    // TODO: 待产品确认 — 登录页背景图/插画资源尚未提供，当前用渐变色占位
    var body: some View {
        ZStack {
            // 背景
            backgroundView

            VStack(spacing: 0) {
                Spacer()

                // App Logo / 插画区
                logoSection

                Spacer()

                // 微信登录按钮
                wechatLoginButton
                    .padding(.horizontal, 24)
                    .padding(.bottom, 16)

                // 用户协议 & 隐私政策
                agreementSection
                    .padding(.bottom, 40)
            }
        }
        // 微信未安装提示
        .alert("请先安装微信", isPresented: $showWeChatNotInstalledAlert) {
            Button("好的", role: .cancel) {}
        } message: {
            Text("OB 需要通过微信登录，请先在设备上安装微信 App。")
        }
        // 用户协议 Sheet
        .sheet(isPresented: $showUserAgreement) {
            // TODO: 待产品确认 — 替换为正式用户协议 URL
            WebViewSheet(
                url: URL(string: "https://www.baidu.com")!,
                isPresented: $showUserAgreement
            )
        }
        // 隐私政策 Sheet
        .sheet(isPresented: $showPrivacyPolicy) {
            // TODO: 待产品确认 — 替换为正式隐私政策 URL
            WebViewSheet(
                url: URL(string: "https://www.baidu.com")!,
                isPresented: $showPrivacyPolicy
            )
        }
    }

    // MARK: - 背景

    private var backgroundView: some View {
        // TODO: 待产品确认 — 替换为设计稿背景图
        LinearGradient(
            colors: [Color(hex: "#F5E8DD"), Color(hex: "#EED3D9").opacity(0.4)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }

    // MARK: - Logo 区

    private var logoSection: some View {
        VStack(spacing: 16) {
            // TODO: 待产品确认 — 替换为正式 App Icon 和插画
            RoundedRectangle(cornerRadius: 24)
                .fill(Color(hex: "#B5C0D0").opacity(0.5))
                .frame(width: 100, height: 100)
                .overlay(
                    Text("OB")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                )

            Text("OB")
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(.primary)

            // TODO: 待产品确认 — Slogan 文案
            Text("遇见真实的朋友")
                .font(.system(size: 15))
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - 微信登录按钮

    private var wechatLoginButton: some View {
        Button(action: handleWeChatLogin) {
            HStack(spacing: 10) {
                // TODO: 微信官方 Logo 图标，当前用 SF Symbol 占位
                Image(systemName: "message.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(Color(hex: "#07C160"))

                Text("微信登录")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.white)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(Color(hex: "#1AAD19"))  // 微信品牌绿
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
    }

    // MARK: - 协议区域

    private var agreementSection: some View {
        HStack(spacing: 4) {
            Text("登录即同意")
                .font(.system(size: 12))
                .foregroundStyle(.secondary)

            Button("《用户协议》") {
                showUserAgreement = true
            }
            .font(.system(size: 12))
            .foregroundStyle(Color(hex: "#B5C0D0"))

            Text("和")
                .font(.system(size: 12))
                .foregroundStyle(.secondary)

            Button("《隐私政策》") {
                showPrivacyPolicy = true
            }
            .font(.system(size: 12))
            .foregroundStyle(Color(hex: "#B5C0D0"))
        }
    }

    // MARK: - 微信登录逻辑

    private func handleWeChatLogin() {
        // 第一步：检查微信是否已安装
        // TODO: 集成微信 SDK 后替换为：WXApi.isWXAppInstalled()
        let isWeChatInstalled = checkWeChatInstalled()
        guard isWeChatInstalled else {
            showWeChatNotInstalledAlert = true
            return
        }

        // 第二步：发起微信授权请求
        // TODO: 集成微信 SDK 后替换为以下真实调用：
        //
        //   let req = SendAuthReq()
        //   req.scope = "snsapi_userinfo"
        //   req.state = UUID().uuidString
        //   WXApi.send(req)
        //
        // 授权结果通过 AppDelegate 的 WXApiDelegate.onResp 回调返回，
        // 拿到 code 后调用自有服务端 /auth/wechat 换取 JWT + 用户状态。
        // 服务端回调后调用：
        //   authManager.handleWeChatAuthSuccess(userInfo:serverStatus:)
        // 或：
        //   authManager.handleWeChatAuthFailure()

        simulateWeChatAuthForDev()
    }

    /// 检查微信是否安装
    /// TODO: 集成微信 SDK 后替换为 WXApi.isWXAppInstalled()
    private func checkWeChatInstalled() -> Bool {
        // 开发阶段模拟已安装
        return true
    }

    /// 开发阶段模拟微信授权流程（SDK 集成后删除此方法）
    private func simulateWeChatAuthForDev() {
        // 模拟网络延迟 0.5s 后返回授权结果
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            // 模拟授权成功，服务端返回 PENDING_PROFILE（新用户）
            let mockUserInfo = WeChatUserInfo(
                openid: "mock_openid_12345",
                nickname: "杰哥",   // 模拟微信昵称预填
                avatarURL: nil      // 模拟头像获取失败场景
            )
            authManager.handleWeChatAuthSuccess(
                userInfo: mockUserInfo,
                serverStatus: "PENDING_PROFILE"
            )
        }
    }
}

// MARK: - Preview

#Preview {
    LoginView()
        .environmentObject(AuthStateManager())
}
