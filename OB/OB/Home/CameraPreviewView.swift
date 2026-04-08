// CameraPreviewView.swift
// OB App - UIViewRepresentable 桥接 AVCaptureVideoPreviewLayer 到 SwiftUI
// 作者：Louis（iOS 客户端）
// 版本：v1.0 · 2026-04-07

import SwiftUI
import AVFoundation

// MARK: - CameraPreviewView

/// 将 AVCaptureVideoPreviewLayer 封装为 SwiftUI View
/// 全屏填充，videoGravity = .resizeAspectFill
struct CameraPreviewView: UIViewRepresentable {

    let session: AVCaptureSession

    func makeUIView(context: Context) -> CameraPreviewUIView {
        let view = CameraPreviewUIView()
        view.previewLayer.session = session
        view.previewLayer.videoGravity = .resizeAspectFill
        view.backgroundColor = .clear
        return view
    }

    func updateUIView(_ uiView: CameraPreviewUIView, context: Context) {
        // session 变化时自动通过 layer 绑定更新，无需额外操作
    }
}

// MARK: - CameraPreviewUIView

/// 内部 UIView，以 AVCaptureVideoPreviewLayer 作为 layer 类型
/// 这样 previewLayer 自动随 view frame 变化而 resize
class CameraPreviewUIView: UIView {

    override class var layerClass: AnyClass {
        AVCaptureVideoPreviewLayer.self
    }

    var previewLayer: AVCaptureVideoPreviewLayer {
        // swiftlint:disable:next force_cast
        layer as! AVCaptureVideoPreviewLayer
    }
}
