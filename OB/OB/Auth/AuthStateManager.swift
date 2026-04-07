// AuthStateManager.swift
// OB App - 注册登录流程全局状态管理
// 作者：Louis（iOS 客户端）
// 版本：v1.0 · 2026-04-04

import SwiftUI
import Combine

// MARK: - 用户注册阶段枚举

/// 驱动整个注册/登录导航的核心状态机
enum RegistrationStep: String, Codable {
    case unknown        // 初始态：App 启动时，尚未从服务端拉取到状态
    case login          // 未登录：展示登录页
    case pendingProfile // 已微信授权，UID 已创建，但昵称/头像尚未填写
    case active         // 资料已完善：直接进首页
}

// MARK: - 微信授权返回数据结构

/// 微信 SDK 授权成功后，服务端换取到的用户信息
/// 头像由服务端异步下载存 CDN 后返回长效 URL（本期返回原始 headimgurl 作为过渡）
struct WeChatUserInfo {
    let openid: String
    let nickname: String?    // 可为空（微信未授权资料时）
    let avatarURL: String?   // 可为空（见 PRD §3.1 异常处理）
}

// MARK: - AuthStateManager

/// 全局单例状态管理器，通过 environmentObject 向所有子视图传递
/// 持久化策略：将 registrationStep 写入 UserDefaults，保证强退后能精准恢复现场
@MainActor
final class AuthStateManager: ObservableObject {

    // MARK: Published 状态

    @Published var registrationStep: RegistrationStep = .unknown
    @Published var wechatUserInfo: WeChatUserInfo? = nil

    // MARK: Published 状态（补充）

    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil

    // MARK: Token 存储

    var accessToken: String? {
        get { UserDefaults.standard.string(forKey: tokenKey) }
        set {
            if let token = newValue {
                UserDefaults.standard.set(token, forKey: tokenKey)
            } else {
                UserDefaults.standard.removeObject(forKey: tokenKey)
            }
        }
    }

    // MARK: 私有常量

    private let stepKey = "OB_RegistrationStep"
    private let tokenKey = "OB_AccessToken"

    // MARK: Init

    init() {
        restore()
    }

    // MARK: - 持久化

    /// 将当前 registrationStep 写入 UserDefaults
    func persist() {
        UserDefaults.standard.set(registrationStep.rawValue, forKey: stepKey)
    }

    /// 从 UserDefaults 恢复上次已知的 registrationStep
    /// 用于 App 冷启动时快速判断展示哪个页面，避免白屏；网络恢复后再用 syncFromServer 覆盖
    func restore() {
        guard
            let raw = UserDefaults.standard.string(forKey: stepKey),
            let step = RegistrationStep(rawValue: raw)
        else {
            registrationStep = .login  // 首次安装，默认展示登录页
            return
        }
        registrationStep = step
    }

    // MARK: - 服务端状态同步

    /// 接收服务端返回的账号状态字符串（PENDING_PROFILE / ACTIVE），更新本地状态机
    /// - Parameter status: 服务端 user.status 字段原始值
    func syncFromServer(status: String) {
        switch status {
        case "PENDING_PROFILE":
            transition(to: .pendingProfile)
        case "ACTIVE":
            transition(to: .active)
        default:
            // TODO: 待产品确认 — 若服务端返回未知 status 值，当前兜底为 .login
            transition(to: .login)
        }
    }

    // MARK: - 状态转移

    /// 统一的状态转移入口，转移后立刻持久化
    func transition(to step: RegistrationStep) {
        registrationStep = step
        persist()
    }

    // MARK: - 微信授权回调处理

    /// 微信授权成功后，服务端完成 code 换 token 流程，调用此方法更新全局状态
    /// - Parameters:
    ///   - userInfo: 服务端返回的用户信息（若获取失败传 nil，昵称/头像不做预填）
    ///   - serverStatus: 服务端返回的账号状态
    func handleWeChatAuthSuccess(userInfo: WeChatUserInfo?, serverStatus: String) {
        wechatUserInfo = userInfo  // nil 时资料页保持空输入框（见 PRD §1 异常处理）
        syncFromServer(status: serverStatus)
    }

    /// 微信授权失败或用户取消
    func handleWeChatAuthFailure() {
        // 保持在登录页，不做状态转移
        // TODO: 待产品确认 — 是否需要弹 Toast 提示用户「授权失败，请重试」
    }

    /// 资料填写完成，进入好友引导页
    func markProfileCompleted() {
        transition(to: .active)
    }

    /// 退出登录（TODO: 待产品确认 — 退出登录是否需要服务端 API 通知注销 token）
    func logout() {
        wechatUserInfo = nil
        accessToken = nil
        UserDefaults.standard.removeObject(forKey: stepKey)
        transition(to: .login)
    }

    // MARK: - 网络请求

    /// Dev 模式：用 mock code 直接调本地后端登录
    func loginWithMockCode(_ code: String) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let response = try await OBAPIClient.shared.login(code: code)
            accessToken = response.accessToken
            let userInfo = WeChatUserInfo(
                openid: response.user.uid,
                nickname: response.user.nickname,
                avatarURL: response.user.avatarUrl
            )
            wechatUserInfo = userInfo
            syncFromServer(status: response.user.status)
        } catch let error as APIError {
            errorMessage = error.message
            scheduleErrorDismiss()
        } catch {
            errorMessage = "网络连接失败，请检查本地服务是否启动"
            scheduleErrorDismiss()
        }
    }

    private func scheduleErrorDismiss() {
        Task {
            try? await Task.sleep(nanoseconds: 2_000_000_000) // 2秒后消失
            errorMessage = nil
        }
    }

    /// 提交用户资料到服务端
    func submitProfile(nickname: String, avatarWxUrl: String?) async throws {
        guard let token = accessToken else {
            throw APIError(statusCode: 401, errorCode: "NO_TOKEN", message: "未登录")
        }
        isLoading = true
        defer { isLoading = false }

        let _ = try await OBAPIClient.shared.completeProfile(
            nickname: nickname,
            avatarWxUrl: avatarWxUrl,
            token: token
        )
        transition(to: .active)
    }
}
