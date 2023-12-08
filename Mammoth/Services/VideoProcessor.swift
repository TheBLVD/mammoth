//
//  VideoProcessor.swift
//  Mammoth
//
//  Created by Benoit Nolens on 01/05/2023.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import Foundation
import AVFoundation

enum VideoCompressionError: Error {
    case invalidData
    case exportFailed(Error)
    case compressedDataUnavailable
}

struct VideoProcessor {
    static func compressVideo(videoUrl: URL, outputSize: CGSize, outputFileType: AVFileType, compressionPreset: String) async throws -> (Data, URL) {
        
        let videoAsset = AVAsset(url: videoUrl)
        let videoTrack = videoAsset.tracks(withMediaType: AVMediaType.video)[0]
        let audioTrack = videoAsset.tracks(withMediaType: AVMediaType.audio).first

        let composition = AVMutableComposition()
        let compositionVideoTrack = composition.addMutableTrack(withMediaType: AVMediaType.video, preferredTrackID: kCMPersistentTrackID_Invalid)!
        let compositionAudioTrack = composition.addMutableTrack(withMediaType: AVMediaType.audio, preferredTrackID: kCMPersistentTrackID_Invalid)!
        
        let transform = videoTrack.preferredTransform
        let videoSize = videoTrack.naturalSize.applying(transform)
        let aspectRatio = videoSize.width / videoSize.height
        
        let targetSize = outputSize
        let targetAspectRatio = targetSize.width / targetSize.height
        
        var scaleFactor: CGFloat = 1.0
        if aspectRatio > targetAspectRatio {
            scaleFactor = targetSize.width / videoSize.width
        } else {
            scaleFactor = targetSize.height / videoSize.height
        }
        
        let transformScale = CGAffineTransform(scaleX: scaleFactor, y: scaleFactor)
        let transformTranslation = CGAffineTransform(translationX: targetSize.width / 2, y: targetSize.height / 2)
        let finalTransform = transformScale.concatenating(transformTranslation)
        
        try compositionVideoTrack.insertTimeRange(CMTimeRangeMake(start: CMTime.zero, duration: videoAsset.duration), of: videoTrack, at: CMTime.zero)
        compositionVideoTrack.preferredTransform = transform.concatenating(finalTransform)
        
        if let audioTrack = audioTrack {
            try compositionAudioTrack.insertTimeRange(CMTimeRangeMake(start: CMTime.zero, duration: videoAsset.duration), of: audioTrack, at: CMTime.zero)
        }
        
        let exportSession = AVAssetExportSession(asset: composition, presetName: compressionPreset)!
        exportSession.outputFileType = outputFileType
        
        let randomId = UUID().uuidString
        exportSession.outputURL = URL(fileURLWithPath: NSTemporaryDirectory() + "compressed_video_\(randomId).mp4")
        
        let exportResult = try await withUnsafeThrowingContinuation { (continuation: UnsafeContinuation<AVAssetExportSession.Status, Error>) in
            exportSession.exportAsynchronously {
                if let error = exportSession.error {
                    continuation.resume(throwing: VideoCompressionError.exportFailed(error))
                } else if exportSession.status == .failed {
                    continuation.resume(throwing: VideoCompressionError.exportFailed(NSError(domain: "Unknown", code: 0, userInfo: nil)))
                } else {
                    continuation.resume(returning: exportSession.status)
                }
            }
        }
        
        guard exportResult == .completed else {
            throw VideoCompressionError.exportFailed(NSError(domain: "Unknown", code: 0, userInfo: nil))
        }
        
        guard let outputUrl = exportSession.outputURL,
              let compressedData = try? Data(contentsOf: exportSession.outputURL!) else {
            throw VideoCompressionError.compressedDataUnavailable
        }
        
        return (compressedData, outputUrl)
    }
    
    static func getVideoSize(url: URL) throws -> Int64 {
        let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
        if let fileSize = attributes[.size] as? Int64 {
            let megabyteSize = fileSize / 1024 / 1024
            return megabyteSize
        }
        return 0
    }
    
    static func getVideoResolution(url: URL) throws -> CGSize {
        let asset = AVAsset(url: url)
        let tracks = asset.tracks(withMediaType: .video)
        guard let track = tracks.first else {
            throw NSError(domain: "Video resolution error", code: 0, userInfo: [NSLocalizedDescriptionKey: "The video file does not contain any video tracks."])
        }
        let size = track.naturalSize
        
        return size
    }
    
    /// Throws if the video size exceeds the maxSize
    static func checkVideoSize(url: URL, maxSizeInMB maxSize: Int) throws -> Void {
        let fileSize = try self.getVideoSize(url: url)
        if fileSize > maxSize {
            throw NSError(domain: "Video size error", code: 0, userInfo: [NSLocalizedDescriptionKey: "The video file size exceeds \(maxSize)MB."])
        }
    }
    
    /// - Returns: `true` if the video needs to be compressed
    static func shouldBeCompressed(url: URL, maxResolution: Int, maxSizeInMB maxSize: Int) throws -> Bool {
        let resolution = try self.getVideoResolution(url: url)
        let size = try self.getVideoSize(url: url)
        if (resolution.width > CGFloat(maxResolution) || resolution.height > CGFloat(maxResolution) || size > maxSize) {
            return true
        }
        return false
    }
}
