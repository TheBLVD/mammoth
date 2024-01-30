//
//  GIF2MP4.swift
//
//  Created by PowHu Yang on 2020/4/24.
//  Copyright © 2020 PowHu Yang. All rights reserved.
//
/* How to use
 let data = try! Data(contentsOf: Bundle.main.url(forResource: "gif", withExtension: "gif")!)
 let tempUrl = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("temp.mp4")
 GIF2MP4(data: data)?.convertAndExport(to: tempUrl, completion: { })
 */

import UIKit
import Foundation
import AVFoundation

class GIF2MP4 {
    
    private(set) var gif: GIF
    private var outputURL: URL!
    private(set) var videoWriter: AVAssetWriter!
    private(set) var videoWriterInput: AVAssetWriterInput!
    private(set) var pixelBufferAdaptor: AVAssetWriterInputPixelBufferAdaptor!
    var videoSize: CGSize {
        //The size of the video must be a multiple of 16
        return CGSize(width: max(1, floor(gif.size.width / 16)) * 16, height: max(1, floor(gif.size.height / 16)) * 16)
    }
    
    init?(data: Data) {
        guard let gif = GIF(data: data) else { return nil }
        self.gif = gif
    }
    
    private func prepare() {
        
        try? FileManager.default.removeItem(at: outputURL)

        let avOutputSettings: [String: Any] = [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: NSNumber(value: Float(videoSize.width)),
            AVVideoHeightKey: NSNumber(value: Float(videoSize.height))
        ]
        
        let sourcePixelBufferAttributesDictionary = [
            kCVPixelBufferPixelFormatTypeKey as String: NSNumber(value: kCVPixelFormatType_32ARGB),
            kCVPixelBufferWidthKey as String: NSNumber(value: Float(videoSize.width)),
            kCVPixelBufferHeightKey as String: NSNumber(value: Float(videoSize.height))
        ]
        
        videoWriter = try! AVAssetWriter(outputURL: outputURL, fileType: AVFileType.mp4)
        videoWriterInput = AVAssetWriterInput(mediaType: AVMediaType.video, outputSettings: avOutputSettings)
        videoWriter.add(videoWriterInput)
        
        pixelBufferAdaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: videoWriterInput, sourcePixelBufferAttributes: sourcePixelBufferAttributesDictionary)
        videoWriter.startWriting()
        videoWriter.startSession(atSourceTime: CMTime.zero)
    }
    
    func convertAndExport(to url: URL, completion: @escaping () -> Void ) {
        outputURL = url
        prepare()

        var index = 0
        var delay = 0.0 - gif.frameDurations[0]
        let queue = DispatchQueue(label: "mediaInputQueue")
        videoWriterInput.requestMediaDataWhenReady(on: queue) {
            var isFinished = true

            while index < self.gif.frames.count {
                if self.videoWriterInput.isReadyForMoreMediaData == false {
                    isFinished = false
                    break
                }
                
                if let cgImage = self.gif.getFrame(at: index) {
                    let frameDuration = self.gif.frameDurations[index]
                    delay += Double(frameDuration)
                    let presentationTime = CMTime(seconds: delay, preferredTimescale: 600)
                    let result = self.addImage(image: UIImage(cgImage: cgImage), withPresentationTime: presentationTime)
                    if result == false {
                        fatalError("addImage() failed")
                    } else {
                        index += 1
                    }
                }
            }
            
            if isFinished {
                self.videoWriterInput.markAsFinished()
                self.videoWriter.finishWriting {
                    DispatchQueue.main.async {
                        completion()
                    }
                }
            } else {
                // Fall through. The closure will be called again when the writer is ready.
            }
        }
    }
    
    private func addImage(image: UIImage, withPresentationTime presentationTime: CMTime) -> Bool {
        guard let pixelBufferPool = pixelBufferAdaptor.pixelBufferPool else {
            print("pixelBufferPool is nil ")
            return false
        }
        let pixelBuffer = pixelBufferFromImage(image: image, pixelBufferPool: pixelBufferPool, size: videoSize)
        return pixelBufferAdaptor.append(pixelBuffer, withPresentationTime: presentationTime)
    }

    private func pixelBufferFromImage(image: UIImage, pixelBufferPool: CVPixelBufferPool, size: CGSize) -> CVPixelBuffer {
        var pixelBufferOut: CVPixelBuffer?
        let status = CVPixelBufferPoolCreatePixelBuffer(kCFAllocatorDefault, pixelBufferPool, &pixelBufferOut)
        if status != kCVReturnSuccess {
            fatalError("CVPixelBufferPoolCreatePixelBuffer() failed")
        }
        let pixelBuffer = pixelBufferOut!

        CVPixelBufferLockBaseAddress(pixelBuffer, CVPixelBufferLockFlags(rawValue: CVOptionFlags(0)))

        let data = CVPixelBufferGetBaseAddress(pixelBuffer)
        let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
        let context = CGContext(data: data, width: Int(size.width), height: Int(size.height),
                                bitsPerComponent: 8, bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer), space: rgbColorSpace, bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue)!

        context.clear(CGRect(x: 0, y: 0, width: size.width, height: size.height))

        let horizontalRatio = size.width / image.size.width
        let verticalRatio = size.height / image.size.height
        let aspectRatio = max(horizontalRatio, verticalRatio) // ScaleAspectFill
        //let aspectRatio = min(horizontalRatio, verticalRatio) // ScaleAspectFit
        let newSize = CGSize(width: image.size.width * aspectRatio, height: image.size.height * aspectRatio)

        let x = newSize.width < size.width ? (size.width - newSize.width) / 2: -(newSize.width-size.width)/2
        let y = newSize.height < size.height ? (size.height - newSize.height) / 2: -(newSize.height-size.height)/2

        context.draw(image.cgImage!, in: CGRect(x: x, y: y, width: newSize.width, height: newSize.height))
        CVPixelBufferUnlockBaseAddress(pixelBuffer, CVPixelBufferLockFlags(rawValue: CVOptionFlags(0)))

        return pixelBuffer
    }
}

import ImageIO
import MobileCoreServices

class GIF {

    private let frameDelayThreshold = 0.02
    private(set) var duration = 0.0
    private(set) var imageSource: CGImageSource!
    private(set) var frames: [CGImage?]!
    private(set) lazy var frameDurations = [TimeInterval]()
    var size: CGSize {
        guard let f = frames.first, let cgImage = f else { return .zero }
        return CGSize(width: cgImage.width, height: cgImage.height)
    }
    private lazy var getFrameQueue: DispatchQueue = DispatchQueue(label: "gif.frame.queue", qos: .userInteractive)

    init?(data: Data) {
        guard let imgSource = CGImageSourceCreateWithData(data as CFData, nil), let imgType = CGImageSourceGetType(imgSource), UTTypeConformsTo(imgType, kUTTypeGIF) else {
            return nil
        }
        self.imageSource = imgSource
        let imgCount = CGImageSourceGetCount(imageSource)
        frames = [CGImage?](repeating: nil, count: imgCount)
        for i in 0..<imgCount {
            let delay = getGIFFrameDuration(imgSource: imageSource, index: i)
            frameDurations.append(delay)
            duration += delay

            getFrameQueue.async { [unowned self] in
                self.frames[i] = CGImageSourceCreateImageAtIndex(self.imageSource, i, nil)
            }
        }
    }

    func getFrame(at index: Int) -> CGImage? {
        if index >= CGImageSourceGetCount(imageSource) {
            return nil
        }
        if let frame = frames[index] {
            return frame
        } else {
            let frame = CGImageSourceCreateImageAtIndex(imageSource, index, nil)
            frames[index] = frame
            return frame
        }
    }

    private func getGIFFrameDuration(imgSource: CGImageSource, index: Int) -> TimeInterval {
        guard let frameProperties = CGImageSourceCopyPropertiesAtIndex(imgSource, index, nil) as? [String: Any],
            let gifProperties = frameProperties[kCGImagePropertyGIFDictionary as String] as? NSDictionary,
            let unclampedDelay = gifProperties[kCGImagePropertyGIFUnclampedDelayTime] as? TimeInterval
            else { return 0.02 }

        var frameDuration = TimeInterval(0)

        if unclampedDelay < 0 {
            frameDuration = gifProperties[kCGImagePropertyGIFDelayTime] as? TimeInterval ?? 0.0
        } else {
            frameDuration = unclampedDelay
        }

        /* Implement as Browsers do: Supports frame delays as low as 0.02 s, with anything below that being rounded up to 0.10 s.
         http://nullsleep.tumblr.com/post/16524517190/animated-gif-minimum-frame-delay-browser-compatibility */

        if frameDuration < frameDelayThreshold - Double.ulpOfOne {
            frameDuration = 0.1
        }

        return frameDuration
    }
}
