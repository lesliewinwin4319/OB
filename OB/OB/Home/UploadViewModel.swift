// UploadViewModel.swift
// OB App - 上传流程 ViewModel（图片压缩 + 预签名 + R2 上传 + 发帖）

import SwiftUI
import Combine

final class UploadViewModel: ObservableObject {
    @Published var isSubmitting: Bool = false

    private let hashableImage: HashableImage

    init(hashableImage: HashableImage) {
        self.hashableImage = hashableImage
    }

    func submit(friend: Friend, navigationPath: Binding<NavigationPath>) async {
        guard !isSubmitting else { return }

        guard let token = KeychainHelper.read(key: "OB_AccessToken") else {
            ToastManager.shared.show("登录状态已失效，请重新登录")
            return
        }

        isSubmitting = true
        defer { isSubmitting = false }

        let image = hashableImage.image
        let compressedData: Data? = await Task.detached(priority: .userInitiated) {
            image.jpegData(compressionQuality: 0.85)
        }.value
        guard let imageData = compressedData else {
            ToastManager.shared.show("图片处理失败，请重拍")
            return
        }

        let fileName = "\(UUID().uuidString).jpg"
        let presignData: PresignData
        do {
            presignData = try await OBAPIClient.shared.presign(
                fileName: fileName,
                contentType: "image/jpeg",
                token: token
            )
        } catch {
            print("[UploadViewModel] presign failed: \(error)")
            ToastManager.shared.show("上传失败，请重试")
            return
        }

        do {
            try await OBAPIClient.shared.putToR2(
                uploadUrl: presignData.uploadUrl,
                imageData: imageData
            )
        } catch {
            print("[UploadViewModel] putToR2 failed: \(error)")
            ToastManager.shared.show("上传失败，请重试")
            return
        }

        do {
            try await OBAPIClient.shared.createPost(
                imageUrl: presignData.imageUrl,
                subjectUid: friend.uid,
                token: token
            )
        } catch {
            print("[UploadViewModel] createPost failed: \(error)")
            ToastManager.shared.show("提交失败，请重试")
            return
        }

        navigationPath.wrappedValue = NavigationPath()
        ToastManager.shared.show("已提交！对方同意后展示在朋友圈")
    }
}
