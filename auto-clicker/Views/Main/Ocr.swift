//
//  Ocr.swift
//  auto-clicker
//
//  Created by Rudy on 2025/2/8.
//

import Cocoa
import Vision
import CoreImage
import opencv2
import ScreenCaptureKit

func getWindows(of appName: String) -> [[String: Any]] {
    // 获取当前屏幕上所有窗口的信息
    guard let windowListInfo = CGWindowListCopyWindowInfo(.optionOnScreenOnly, kCGNullWindowID) as? [[String: Any]] else {
        print("无法获取窗口列表")
        return []
    }

    // 过滤窗口，匹配应用名称
    let filteredWindows = windowListInfo.filter { window in
        if let ownerName = window[kCGWindowOwnerName as String] as? String {
            return ownerName.lowercased() == appName.lowercased()
        }
        return false
    }

    return filteredWindows
}


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
            print("\(candidate.string)")
            // 匹配目标文字
            
            if candidate.string.contains(text) {
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
    request.recognitionLanguages = ["zh-Hans", "zh-Hant"]  // 设定中文语言支持
    request.usesLanguageCorrection = true  // 开启语言纠正，提高识别准确率
    // 执行识别请求
    do {
        try requestHandler.perform([request])
    } catch {
        print("文字识别失败: \(error.localizedDescription)")
        return nil
    }
    
    return resultRect
}

func findTextLocation(_ text: String) async throws -> CGRect? {
    
    guard let mainScreen = NSScreen.main else { return nil }
    let screenRect = mainScreen.frame
    
    
    if let (image, frame) = try? await takeScreenshot("com.tencent.WeWorkMac"),
       let cgImage = image,
        let rect = frame {
        
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
                if candidate.string.contains(text) {
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
                    
                    let textX = rect.origin.x + (textXPercent / rect.size.width)
                    let textY = rect.origin.y + ((1 - textYPercent - textHeightPercent) * rect.size.height) // Y 轴翻转
                    let textWidth = textWidthPercent * rect.size.width
                    let textHeight = textHeightPercent * rect.size.height
                    
                    // 返回文字在屏幕上的具体坐标
                    resultRect = CGRect(x: textX, y: textY, width: textWidth, height: textHeight)
                    break
                }
            }
        }
        
        // 设置识别参数
        request.recognitionLevel = .accurate
        request.recognitionLanguages = ["zh-Hans", "zh-Hant"]  // 设定中文语言支持
        request.usesLanguageCorrection = true  // 开启语言纠正，提高识别准确率
        
        // 执行识别请求
        do {
            try requestHandler.perform([request])
        } catch {
            print("文字识别失败: \(error.localizedDescription)")
            return nil
        }
        
        return  resultRect
        
    } else {
        return  nil
    }
}

//func findIconLocation(iconImage: NSImage, similarityThreshold: Float = 0.9) -> CGRect? {
//    // 获取屏幕信息
//    guard let mainScreen = NSScreen.main else { return nil }
//    let screenFrame = mainScreen.frame
//    
//    // 截取屏幕图像
//    guard let screenCGImage =  (
//        screenFrame,
//        .optionOnScreenOnly,
//        kCGNullWindowID,
//        []
//    ) else {
//        print("无法获取屏幕截图，请检查屏幕录制权限")
//        return nil
//    }
//    
//    
//    // 将目标图标转换为 CIImage
////    guard let data = iconImage.tiffRepresentation,
////          let bitmap = NSBitmapImageRep(data: data) else {
////        print("无法转换目标图标为 CIImage")
////    }
////    let iconCIImage = CIImage(bitmapImageRep: bitmap)
//    
//    guard let iconCGImage = iconImage.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
//        print("无法加载图标")
//        return nil
//    }
//    
//    
//    return isIconInScreenshot(screenCGImage: screenCGImage, iconImage: iconCGImage)
//}

/// **检查屏幕截图是否包含目标图标**
func isIconInScreenshot(screenCGImage: CGImage, iconImage: CGImage) -> CGRect? {
    Imgcodecs.imread(filename: "/Users/rudy/Desktop/plus.png", flags: 1)
//    imread(String filename, int flags = IMREAD_COLOR_BGR)
    
    // 1. **转换 CGImage 为 CIImage**
    let screenCIImage = CIImage(cgImage: screenCGImage)
    let iconCIImage = CIImage(cgImage: iconImage)

    // 2. **使用模板匹配 (`CIMatchTemplate`)**
    let filter = CIFilter(name: "CIMatchTemplate")!
    filter.setValue(screenCIImage, forKey: kCIInputImageKey)
    filter.setValue(iconCIImage, forKey: "inputTargetImage")

    // 3. **获取匹配输出**
    guard let outputImage = filter.outputImage else {
        print("模板匹配失败")
        return nil
    }

    // 4. **创建 CIContext 以处理输出**
    let context = CIContext()
    let outputBitmap = context.createCGImage(outputImage, from: outputImage.extent)
    let pixelData = outputBitmap?.dataProvider?.data
    guard let data = CFDataGetBytePtr(pixelData) else {
        print("无法读取匹配结果")
        return nil
    }

    // 5. **遍历输出图像，找到最佳匹配点**
    var maxScore: Float = -1.0
    var bestPoint = CGPoint.zero
    let width = Int(outputImage.extent.width)
    let height = Int(outputImage.extent.height)

    for y in 0..<height {
        for x in 0..<width {
            let index = (y * width + x) * 4  // 读取像素数据
            let value = Float(data[index]) / 255.0
            if value > maxScore {
                maxScore = value
                bestPoint = CGPoint(x: x, y: y)
            }
        }
    }

    // 6. **设定匹配阈值**
    if maxScore > 0.8 { // 设定匹配度大于 80% 才算找到
        print("找到图标坐标: \(bestPoint)")
        return CGRect(origin: bestPoint, size: CGSize(width: iconImage.width, height: iconImage.height))
    }

    print("未找到图标")
    return nil
}

func takeScreenshot(_ bundleIdentifier: String) async throws -> (CGImage?, CGRect?) {
    
    do {
        let windows = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true).windows
        let window = windows.filter { window in
            window.owningApplication?.bundleIdentifier == bundleIdentifier && window.isOnScreen && window.frame.size.width > 300 && window.frame.size.height > 300
        }[0]
        let filter = SCContentFilter(desktopIndependentWindow: window)
        let configuration = SCStreamConfiguration()
        configuration.ignoreShadowsSingleWindow = false
        configuration.showsCursor = false
        configuration.width = Int(Float(filter.contentRect.width))
        configuration.height = Int(Float(filter.contentRect.height))
        print(filter.contentRect)
        let capturedImage = try await SCScreenshotManager.captureImage(contentFilter: filter, configuration: configuration)
        
        // 新增：保存截图到桌面
        do {
            let desktopURL = FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask).first!
            let screenshotURL = desktopURL.appendingPathComponent("screenshot_\(Date().timeIntervalSince1970).png")
            
            let bitmapRep = NSBitmapImageRep(cgImage: capturedImage)
            let pngData = bitmapRep.representation(using: .png, properties: [:])
            
            try pngData?.write(to: screenshotURL)
            print("截图已保存到：\(screenshotURL.path)")
        } catch {
            print("截图保存失败：\(error.localizedDescription)")
        }
        return (capturedImage, window.frame)
    } catch {
        print("Error capturing screen: \(error)")
        throw error
        
    }
}
