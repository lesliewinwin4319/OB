// PhotoAlbumSaver.swift
// OB App - 相册保存工具：权限检查 + 异步写入
// 作者：Louis（iOS 客户端）
// 版本：v1.0 · 2026-04-08

import Photos
import UIKit

// MARK: - PhotoAlbumSaver

/// 封装 PHPhotoLibrary 的 .addOnly 权限检查和照片写入
/// 保存结果不阻塞业务流程，仅通过 Toast 提示权限问题
enum PhotoAlbumSaver {

    /// 异步保存照片到系统相册
    /// - Parameter image: 要保存的 UIImage
    /// - 权限被拒绝时通过 ToastManager 提示用户
    /// - 保存失败仅 log，不阻塞主流程
    @MainActor
    static func save(_ image: UIImage) {
        Task.detached {
            let status = await PHPhotoLibrary.requestAuthorization(for: .addOnly)

            switch status {
            case .authorized, .limited:
                // 有权限，执行写入
                do {
                    try await PHPhotoLibrary.shared().performChanges {
                        PHAssetChangeRequest.creationRequestForAsset(from: image)
                    }
                } catch {
                    // 写入失败（存储空间不足等），不阻塞业务
                    print("[PhotoAlbumSaver] 写入相册失败: \(error.localizedDescription)")
                }

            case .denied, .restricted:
                // 权限被拒绝，Toast 提示
                await MainActor.run {
                    ToastManager.shared.show("请授权OB相册权限以保存照片")
                }

            case .notDetermined:
                // 理论上不会走到这里（requestAuthorization 会弹窗）
                break

            @unknown default:
                break
            }
        }
    }
}
