// OBAPIClient.swift
// OB App - HTTP 网络层
// 作者：Louis（iOS 客户端）
// 版本：v1.0 · 2026-04-06

import Foundation

// MARK: - 响应数据结构

struct LoginResponse: Decodable {
    let accessToken: String
    let user: UserResponse

    enum CodingKeys: String, CodingKey {
        case accessToken = "token"
        case user
    }
}

struct UserResponse: Decodable {
    let uid: String
    let status: String
    let nickname: String?
    let avatarUrl: String?
    let createdAt: String?
}

struct ProfileResponse: Decodable {
    let uid: String
    let status: String
    let nickname: String?
    let avatarUrl: String?
}

// MARK: - API 错误

struct APIError: Decodable, Error {
    let statusCode: Int
    let errorCode: String
    let message: String
}

// MARK: - OBAPIClient

final class OBAPIClient {

    static let shared = OBAPIClient()

    // 生产环境：Railway 部署地址，统一走 /api/v1 前缀
    private let baseURL = "https://ob-production-8afc.up.railway.app/api/v1"

    private let session: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 15
        return URLSession(configuration: config)
    }()

    private init() {}

    // MARK: - POST /auth/wechat/login

    /// 微信 code 换取 JWT，首次自动注册
    func login(code: String) async throws -> LoginResponse {
        let body = ["code": code]
        return try await post(path: "/auth/wechat/login", body: body, token: nil)
    }

    // MARK: - POST /users/me/profile

    /// 填写昵称和头像，PENDING_PROFILE → ACTIVE
    func completeProfile(
        nickname: String,
        avatarWxUrl: String?,
        token: String
    ) async throws -> ProfileResponse {
        var body: [String: String] = ["nickname": nickname]
        if let url = avatarWxUrl, !url.isEmpty {
            body["avatarWxUrl"] = url
        }
        return try await post(path: "/users/me/profile", body: body, token: token)
    }

    // MARK: - GET /users/me

    /// 获取当前用户信息
    func getMe(token: String) async throws -> UserResponse {
        return try await get(path: "/users/me", token: token)
    }

    // MARK: - 内部通用方法

    private func post<T: Decodable>(
        path: String,
        body: [String: String],
        token: String?
    ) async throws -> T {
        var request = makeRequest(path: path, method: "POST", token: token)
        request.httpBody = try JSONEncoder().encode(body)
        return try await execute(request)
    }

    private func get<T: Decodable>(path: String, token: String) async throws -> T {
        let request = makeRequest(path: path, method: "GET", token: token)
        return try await execute(request)
    }

    private func makeRequest(path: String, method: String, token: String?) -> URLRequest {
        var request = URLRequest(url: URL(string: baseURL + path)!)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let token {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        return request
    }

    private func execute<T: Decodable>(_ request: URLRequest) async throws -> T {
        let (data, response) = try await session.data(for: request)
        let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0

        if (200..<300).contains(statusCode) {
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            return try decoder.decode(T.self, from: data)
        } else {
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            if let apiError = try? decoder.decode(APIError.self, from: data) {
                throw apiError
            }
            throw APIError(statusCode: statusCode, errorCode: "UNKNOWN", message: "请求失败")
        }
    }
}
