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

struct MyPostsResponse: Decodable {
    let pendingList: [PostItem]
    let approvedList: [PostItem]
    let pendingCount: Int

    enum CodingKeys: String, CodingKey {
        case pendingList
        case approvedList
        case pendingCount
    }
}

struct PostItem: Decodable {
    let id: String
    let photographerNickname: String
    let imageUrl: String
    let createdAt: String
    let status: String

    enum CodingKeys: String, CodingKey {
        case id
        case photographerNickname
        case imageUrl
        case createdAt
        case status
    }
}

struct PendingCountResponse: Decodable {
    let pendingCount: Int

    enum CodingKeys: String, CodingKey {
        case pendingCount
    }
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

    // MARK: - GET /users/me/posts

    func getMyPosts(token: String) async throws -> MyPostsResponse {
        let response: DataResponse<MyPostsResponse> = try await get(path: "/users/me/posts", token: token)
        return response.data
    }

    // MARK: - PATCH /posts/{postId}/review

    func reviewPost(postId: String, action: String, token: String) async throws {
        let body = ReviewPostRequest(action: action)
        try await requestVoid(path: "/posts/\(postId)/review", method: "PATCH", body: body, token: token)
    }

    // MARK: - GET /users/me/badge

    func getPendingCount(token: String) async throws -> PendingCountResponse {
        let response: DataResponse<PendingCountResponse> = try await get(path: "/users/me/badge", token: token)
        return response.data
    }

    // MARK: - PUT /users/me/device-token

    func registerDeviceToken(deviceToken: String, token: String) async throws {
        let body = RegisterDeviceTokenRequest(deviceToken: deviceToken, platform: "ios")
        try await requestVoid(path: "/users/me/device-token", method: "PUT", body: body, token: token)
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

    private func requestVoid(path: String, method: String, body: Encodable?, token: String?) async throws {
        var request = makeRequest(path: path, method: method, token: token)
        if let body {
            request.httpBody = try? JSONEncoder().encode(AnyEncodable(body))
        }
        let (_, response) = try await session.data(for: request)
        let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
        guard (200..<300).contains(statusCode) else {
            throw APIError(statusCode: statusCode, errorCode: "REQUEST_FAILED", message: "请求失败")
        }
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

private struct DataResponse<T: Decodable>: Decodable {
    let data: T
}

private struct ReviewPostRequest: Encodable {
    let action: String
}

private struct RegisterDeviceTokenRequest: Encodable {
    let deviceToken: String
    let platform: String
}

private struct AnyEncodable: Encodable {
    private let encoder: (Encoder) throws -> Void

    init(_ wrapped: Encodable) {
        self.encoder = wrapped.encode(to:)
    }

    func encode(to encoder: Encoder) throws {
        try self.encoder(encoder)
    }
}

struct PresignData: Decodable {
    let uploadUrl: String
    let imageUrl: String
    let expiresIn: Int
}

private struct PresignRequest: Encodable {
    let fileName: String
    let contentType: String
}

private struct CreatePostRequest: Encodable {
    let imageUrl: String
    let subjectUid: String
}

extension OBAPIClient {

    func presign(fileName: String, contentType: String, token: String) async throws -> PresignData {
        let body = PresignRequest(fileName: fileName, contentType: contentType)
        var request = makeRequest(path: "/upload/presign", method: "POST", token: token)
        request.httpBody = try JSONEncoder().encode(body)

        let response: DataResponse<PresignData> = try await execute(request)
        return response.data
    }

    func putToR2(uploadUrl: String, imageData: Data) async throws {
        guard let url = URL(string: uploadUrl) else {
            throw APIError(statusCode: 0, errorCode: "INVALID_URL", message: "上传地址无效")
        }

        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("image/jpeg", forHTTPHeaderField: "Content-Type")
        request.httpBody = imageData

        let (_, response) = try await session.data(for: request)
        let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
        guard (200..<300).contains(statusCode) else {
            throw APIError(statusCode: statusCode, errorCode: "UPLOAD_FAILED", message: "图片上传失败")
        }
    }

    func createPost(imageUrl: String, subjectUid: String, token: String) async throws {
        let body = CreatePostRequest(imageUrl: imageUrl, subjectUid: subjectUid)
        try await requestVoid(path: "/posts", method: "POST", body: body, token: token)
    }
}
