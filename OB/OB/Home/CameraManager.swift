// CameraManager.swift
// OB App - 相机管理器：封装 AVCaptureSession 生命周期和权限状态机
// 作者：Louis（iOS 客户端）
// 版本：v1.0 · 2026-04-07

import AVFoundation
import SwiftUI
import Combine

// MARK: - 相机权限枚举

/// 简化后的权限状态，比系统 AVAuthorizationStatus 多了 noHardware 分支
enum CameraPermission: Equatable {
    case notDetermined   // 首次，尚未请求过权限
    case authorized      // 已授权
    case denied          // 被拒绝（含 restricted）
    case noHardware      // 无摄像头硬件（模拟器等）
}

// MARK: - CameraManager

@MainActor
final class CameraManager: ObservableObject {

    // MARK: Published 状态

    @Published var permissionStatus: CameraPermission = .notDetermined
    @Published var isSessionRunning: Bool = false
    @Published var sessionError: String? = nil

    // MARK: 内部持有

    /// AVCaptureSession 仅内部使用，外部通过 sessionForPreview 只读访问
    let captureSession = AVCaptureSession()

    /// 专用后台队列，避免在主线程启停 session 导致 UI 卡顿
    private let sessionQueue = DispatchQueue(label: "com.ob.camera.session")

    /// 当前使用的摄像设备（后置广角）
    private var currentDevice: AVCaptureDevice?

    /// 用户在本次生命周期内手动取消了权限弹窗，不再自动弹出
    @Published var userDismissedAlert: Bool = false

    // MARK: - 权限检查与请求

    /// HomeView.onAppear 时调用，驱动整个权限状态机
    func checkAndRequestPermission() {
        // 1. 硬件检查：无摄像头则直接进 noHardware
        guard AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) != nil else {
            permissionStatus = .noHardware
            return
        }

        // 2. 读取当前系统权限状态
        let status = AVCaptureDevice.authorizationStatus(for: .video)

        switch status {
        case .notDetermined:
            // 首次：弹出系统权限弹窗
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                Task { @MainActor in
                    guard let self else { return }
                    if granted {
                        self.permissionStatus = .authorized
                        self.setupAndStartSession()
                    } else {
                        self.permissionStatus = .denied
                    }
                }
            }

        case .authorized:
            permissionStatus = .authorized
            setupAndStartSession()

        case .denied, .restricted:
            permissionStatus = .denied

        @unknown default:
            permissionStatus = .denied
        }
    }

    /// 从系统设置返回后二次自检（延迟 0.3s，确保系统更新完毕）
    func recheckPermission() {
        // 无硬件时不需要重复检查
        guard permissionStatus != .noHardware else { return }

        Task {
            try? await Task.sleep(nanoseconds: 300_000_000) // 0.3s

            let status = AVCaptureDevice.authorizationStatus(for: .video)

            switch status {
            case .authorized:
                if self.permissionStatus != .authorized {
                    self.permissionStatus = .authorized
                    self.userDismissedAlert = false // 重置弹窗取消标记
                    self.setupAndStartSession()
                }

            case .denied, .restricted:
                if self.permissionStatus == .authorized {
                    // 用户在设置中关闭了权限
                    self.stopSession()
                    self.permissionStatus = .denied
                    self.userDismissedAlert = false // 重置，允许弹窗再次弹出
                }

            default:
                break
            }
        }
    }

    // MARK: - Session 管理

    /// 配置并启动 AVCaptureSession（在后台线程执行）
    private func setupAndStartSession() {
        sessionQueue.async { [weak self] in
            guard let self else { return }

            // 避免重复配置
            guard self.captureSession.inputs.isEmpty else {
                // 已配置过，只需启动
                if !self.captureSession.isRunning {
                    self.captureSession.startRunning()
                    Task { @MainActor in
                        self.isSessionRunning = true
                    }
                }
                return
            }

            self.captureSession.beginConfiguration()
            self.captureSession.sessionPreset = .photo

            // 添加后置广角摄像头输入
            guard let device = AVCaptureDevice.default(
                .builtInWideAngleCamera, for: .video, position: .back
            ) else {
                Task { @MainActor in
                    self.sessionError = "相机启动失败，请重启应用"
                }
                self.captureSession.commitConfiguration()
                return
            }

            do {
                let input = try AVCaptureDeviceInput(device: device)
                if self.captureSession.canAddInput(input) {
                    self.captureSession.addInput(input)
                    Task { @MainActor in
                        self.currentDevice = device
                    }
                } else {
                    Task { @MainActor in
                        self.sessionError = "相机启动失败，请重启应用"
                    }
                    self.captureSession.commitConfiguration()
                    return
                }
            } catch {
                Task { @MainActor in
                    self.sessionError = "相机启动失败，请重启应用"
                }
                self.captureSession.commitConfiguration()
                return
            }

            self.captureSession.commitConfiguration()
            self.captureSession.startRunning()

            Task { @MainActor in
                self.isSessionRunning = self.captureSession.isRunning
                if !self.captureSession.isRunning {
                    self.sessionError = "相机启动失败，请重启应用"
                }
            }
        }
    }

    /// 停止 session（在后台线程执行）
    func stopSession() {
        sessionQueue.async { [weak self] in
            guard let self else { return }
            if self.captureSession.isRunning {
                self.captureSession.stopRunning()
            }
            Task { @MainActor in
                self.isSessionRunning = false
            }
        }
    }

    // MARK: - Tap-to-Focus

    /// 设置对焦点和曝光点
    /// - Parameter point: 归一化坐标（0~1 范围），由 CameraPreviewView 转换传入
    func focusAt(point: CGPoint) {
        guard let device = currentDevice else { return }

        sessionQueue.async {
            do {
                try device.lockForConfiguration()

                if device.isFocusPointOfInterestSupported {
                    device.focusPointOfInterest = point
                    device.focusMode = .autoFocus
                }

                if device.isExposurePointOfInterestSupported {
                    device.exposurePointOfInterest = point
                    device.exposureMode = .autoExpose
                }

                device.unlockForConfiguration()
            } catch {
                // 对焦失败不影响主流程，静默忽略
            }
        }
    }
}
