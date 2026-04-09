// PhotoConfirmationView.swift
// OB App - 拍照确认页：全屏预览照片 + 放弃/确定操作
// 作者：Louis（iOS 客户端）
// 版本：v1.0 · 2026-04-08

import SwiftUI

// MARK: - PhotoConfirmationView

/// 拍照确认页
/// - 黑色全屏背景
/// - 左上角 X 按钮（放弃，需二次确认）
/// - 中央照片预览（降采样后的 previewImage）
/// - 底部白色圆角"确定"按钮
struct PhotoConfirmationView: View {

    let hashableImage: HashableImage
    @Binding var navigationPath: NavigationPath

    /// 放弃二次确认弹窗
    @State private var showDiscardAlert = false

    /// 降采样后的预览图（避免全分辨率占用过多内存）
    @State private var previewImage: UIImage?

    var body: some View {
        ZStack {
            // 黑色全屏背景
            Color.black
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // 顶部栏：左上角 X 按钮
                HStack {
                    Button(action: {
                        showDiscardAlert = true
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundStyle(.white)
                            .frame(width: 44, height: 44)
                    }
                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.top, 8)

                Spacer()

                // 中央：照片预览
                if let preview = previewImage {
                    Image(uiImage: preview)
                        .resizable()
                        .scaledToFit()
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .padding(.horizontal, 20)
                } else {
                    // 降采样过程中的占位
                    ProgressView()
                        .tint(.white)
                }

                Spacer()

                // 底部：确定按钮
                Button(action: {
                    navigationPath.append(PhotoFlowRoute.uploadSelection)
                }) {
                    Text("确定")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(Color(hex: "#333333"))
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 25))
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 40)
            }
        }
        .navigationBarBackButtonHidden(true)
        .disableSwipeBack()
        .alert("确定要放弃吗？", isPresented: $showDiscardAlert) {
            Button("否", role: .cancel) {}
            Button("是", role: .destructive) {
                // Pop to Root：清空导航栈回首页
                navigationPath = NavigationPath()
            }
        }
        .onAppear {
            // 异步降采样，避免阻塞主线程
            let original = hashableImage.image
            Task.detached {
                let screenWidth = await UIScreen.main.bounds.width
                let downsampled = ImageUtils.downsample(original, toWidth: screenWidth)
                await MainActor.run {
                    previewImage = downsampled
                }
            }
        }
    }
}
