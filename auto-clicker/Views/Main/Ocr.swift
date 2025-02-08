//
//  Ocr.swift
//  auto-clicker
//
//  Created by Rudy on 2025/2/8.
//

import Cocoa
import Vision

func findTextLocation(_ text: String) -> CGRect? {
    // 获取主屏幕信息
    guard let mainScreen = NSScreen.main else { return nil }
    let screenRect = mainScreen.frame
    let scaleFactor = mainScreen.backingScaleFactor
    
    // 截取屏幕图像（需要开启屏幕录制权限）
    guard let cgImage = CGWindowListCreateImage(
        screenRect,
        .optionOnScreenOnly,
        kCGNullWindowID,
        []
    ) else {
        print("无法获取屏幕截图，请检查屏幕录制权限")
        return nil
    }
    
    
    // 新增：保存截图到桌面
    do {
        let desktopURL = FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask).first!
        let screenshotURL = desktopURL.appendingPathComponent("screenshot_\(Date().timeIntervalSince1970).png")
        
        let bitmapRep = NSBitmapImageRep(cgImage: cgImage)
        let pngData = bitmapRep.representation(using: .png, properties: [:])
        
        try pngData?.write(to: screenshotURL)
        print("截图已保存到：\(screenshotURL.path)")
    } catch {
        print("截图保存失败：\(error.localizedDescription)")
    }
    
    // 创建图像请求处理器
    let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])
    
    // 存储识别结果
    var resultRect: CGRect? = nil
    
    // 创建文字识别请求
    let request = VNRecognizeTextRequest { request, error in
        guard let observations = request.results as? [VNRecognizedTextObservation], error == nil else {
            return
        }
        
        // 遍历识别结果
        for observation in observations {
            guard let candidate = observation.topCandidates(1).first else { continue }
            
            // 匹配目标文字
            if candidate.string == text {
                // 获取 Vision 返回的归一化坐标（百分比）
                let boundingBox = observation.boundingBox
                
                // 计算文字在图片中的百分比位置
                let textXPercent = boundingBox.origin.x
                let textYPercent = boundingBox.origin.y
                let textWidthPercent = boundingBox.size.width
                let textHeightPercent = boundingBox.size.height
                
                // 将百分比转换为屏幕坐标
                let screenWidth = screenRect.width
                let screenHeight = screenRect.height
                
                let textX = screenRect.origin.x + (textXPercent * screenWidth)
                let textY = screenRect.origin.y + ((1 - textYPercent - textHeightPercent) * screenHeight) // Y 轴翻转
                let textWidth = textWidthPercent * screenWidth
                let textHeight = textHeightPercent * screenHeight
                
                // 返回文字在屏幕上的具体坐标
                resultRect = CGRect(x: textX, y: textY, width: textWidth, height: textHeight)
                break
            }
        }
    }
    
    // 设置识别参数
    request.recognitionLevel = .accurate
    request.usesLanguageCorrection = false  // 关闭语言校正以提升速度
    
    // 执行识别请求
    do {
        try requestHandler.perform([request])
    } catch {
        print("文字识别失败: \(error.localizedDescription)")
        return nil
    }
    
    return resultRect
}

//// 使用示例
//if let location = findTextLocation("Hello World") {
//    print("文字坐标: \(location)")
//} else {
//    print("未找到文字")
//}
