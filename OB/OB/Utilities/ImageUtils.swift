// ImageUtils.swift
// OB App - 图片工具函数（降采样等）
// 作者：Louis（iOS 客户端）
// 版本：v1.0 · 2026-04-08

import UIKit
import ImageIO

// MARK: - ImageUtils

enum ImageUtils {

    /// 图片降采样，用于预览展示，避免全分辨率原图占用过多内存
    /// - Parameters:
    ///   - image: 原始 UIImage
    ///   - targetWidth: 目标宽度（pt），实际像素 = targetWidth * scale
    /// - Returns: 降采样后的 UIImage，失败时返回原图
    static func downsample(_ image: UIImage, toWidth targetWidth: CGFloat) -> UIImage {
        guard let cgImage = image.cgImage else { return image }

        let scale = UIScreen.main.scale
        let maxPixelWidth = targetWidth * scale

        // 若原图已经小于目标宽度，无需降采样
        if CGFloat(cgImage.width) <= maxPixelWidth {
            return image
        }

        let data = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(data, "public.jpeg" as CFString, 1, nil) else {
            return image
        }
        CGImageDestinationAddImage(destination, cgImage, nil)
        CGImageDestinationFinalize(destination)

        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: maxPixelWidth,
        ]

        guard let source = CGImageSourceCreateWithData(data as CFData, nil),
              let thumbnailRef = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary)
        else {
            return image
        }

        return UIImage(cgImage: thumbnailRef, scale: scale, orientation: image.imageOrientation)
    }
}
