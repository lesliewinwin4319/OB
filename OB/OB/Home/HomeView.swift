// HomeView.swift
// OB App - 首页容器视图：相机预览 + 权限状态机 + UI 覆盖层 + 拍照流程路由
// 作者：Louis（iOS 客户端）
// 版本：v1.1 · 2026-04-08（新增 NavigationStack 拍照流程路由）

import SwiftUI

// MARK: - HomeView

/// 首页容器视图，替换 RootView 中的占位 HomeView
/// 采用 NavigationStack 包裹，支持拍照 -> 确认 -> 上传选择的完整流程
/// ZStack 分层结构：相机预览（底层）-> 导航栏 -> 拍照按钮 -> 对焦动画 -> 权限弹窗
struct HomeView: View {
    @EnvironmentObject var authManager: AuthStateManager
    @StateObject private var cameraManager = CameraManager()
    @Environment(\.scenePhase) private var scenePhase

    /// 拍照流程导航路径
    @State private var navigationPath = NavigationPath()

    var body: some View {
        NavigationStack(path: $navigationPath) {
            ZStack {
                // Layer 1: 相机预览 或 黑屏背景
                if cameraManager.permissionStatus == .authorized {
                    // 相机预览
                    CameraPreviewView(session: cameraManager.captureSession)
                        .ignoresSafeArea()

                    // 对焦交互层（仅在相机运行时可用）
                    TapToFocusOverlay { point in
                        cameraManager.focusAt(point: point)
                    }
                } else {
                    // 黑屏背景
                    Color(hex: "#1A1A1A")
                        .ignoresSafeArea()
                }

                // Layer 2: 顶部导航栏 + 底部按钮区
                VStack {
                    // 顶部导航栏
                    TopNavigationBar { tabName in
                        ToastManager.shared.show("功能开发中，敬请期待")
                    }
                    .padding(.top, 8)

                    Spacer()

                    // 底部区域：拍照按钮 + 朋友圈入口
                    VStack(spacing: 20) {
                        // 拍照按钮
                        CaptureButton(
                            isEnabled: cameraManager.permissionStatus == .authorized,
                            isCapturing: cameraManager.isCapturing,
                            onCapture: {
                                cameraManager.capturePhoto()
                            }
                        )

                        // 底部「朋友圈」入口
                        Button(action: {
                            ToastManager.shared.show("功能开发中，敬请期待")
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: "circle.grid.2x2.fill")
                                    .font(.system(size: 16))
                                Text("朋友圈")
                                    .font(.system(size: 14, weight: .medium))
                            }
                            .foregroundStyle(.white.opacity(0.8))
                        }
                        .padding(.bottom, 16)
                    }
                }

                // Layer 3: 权限拒绝弹窗（denied 且用户未手动关闭时立即弹出）
                if cameraManager.permissionStatus == .denied && !cameraManager.userDismissedAlert {
                    CameraPermissionAlert(onDismiss: {
                        cameraManager.userDismissedAlert = true
                    })
                    .transition(.opacity)
                    .animation(.easeOut(duration: 0.25), value: cameraManager.userDismissedAlert)
                }
            }
            .navigationBarBackButtonHidden(true)
            // MARK: 路由目的地注册
            .navigationDestination(for: PhotoFlowRoute.self) { route in
                switch route {
                case .confirmation(let hashableImage):
                    PhotoConfirmationView(
                        hashableImage: hashableImage,
                        navigationPath: $navigationPath
                    )
                case .uploadSelection:
                    UploadSelectionView(
                        navigationPath: $navigationPath
                    )
                }
            }
        }
        .onAppear {
            cameraManager.checkAndRequestPermission()
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                cameraManager.recheckPermission()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)) { _ in
            // App 即将进入后台时不需要特殊处理，session 会自动暂停
        }
        // 监听拍照结果，成功后 push 到确认页
        .onChange(of: cameraManager.capturedImage) { _, newImage in
            if let image = newImage {
                let hashableImage = HashableImage(image)
                navigationPath.append(PhotoFlowRoute.confirmation(hashableImage))
            }
        }
        // 监听导航栈变化，Pop to Root 时清理状态
        .onChange(of: navigationPath.count) { _, newCount in
            if newCount == 0 {
                cameraManager.clearCapturedImage()
            }
        }
        // 处理 session 启动失败的 Toast
        .onChange(of: cameraManager.sessionError) { _, error in
            if let error {
                ToastManager.shared.show(error)
                cameraManager.sessionError = nil
            }
        }
    }
}
