// KeychainHelper.swift
// OB App - 基于原生 Security 框架的 Keychain 封装
// 作者：Louis（iOS 客户端）
// 版本：v1.0 · 2026-04-11

import Foundation
import Security

/// 轻量封装，只暴露字符串级别的增/改、读、删三个操作
/// service 统一为 Bundle ID，保证 App 卸载重装后自动清除（iOS 默认行为）
enum KeychainHelper {

    private static let service = Bundle.main.bundleIdentifier ?? "app.ob.ios"

    // MARK: - 写入（新增或更新）

    /// 将字符串值写入 Keychain
    /// - Returns: 操作是否成功
    @discardableResult
    static func save(key: String, value: String) -> Bool {
        guard let data = value.data(using: .utf8) else { return false }

        // 先尝试更新已有条目
        let updateQuery: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: key
        ]
        let updateAttributes: [CFString: Any] = [kSecValueData: data]
        let updateStatus = SecItemUpdate(updateQuery as CFDictionary, updateAttributes as CFDictionary)

        if updateStatus == errSecSuccess {
            return true
        }

        // 条目不存在，新增
        let addQuery: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: key,
            kSecValueData: data,
            // 仅设备解锁后可读，兼顾安全性与可用性
            kSecAttrAccessible: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        ]
        return SecItemAdd(addQuery as CFDictionary, nil) == errSecSuccess
    }

    // MARK: - 读取

    /// 读取 Keychain 中存储的字符串值，不存在时返回 nil
    static func read(key: String) -> String? {
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: key,
            kSecReturnData: true,
            kSecMatchLimit: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess,
              let data = result as? Data,
              let value = String(data: data, encoding: .utf8) else {
            return nil
        }
        return value
    }

    // MARK: - 删除

    /// 删除 Keychain 中指定 key 的条目
    /// - Returns: 操作是否成功（条目不存在时也视为成功）
    @discardableResult
    static func delete(key: String) -> Bool {
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: key
        ]
        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess || status == errSecItemNotFound
    }
}
