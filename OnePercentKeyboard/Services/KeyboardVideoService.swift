import Foundation
import AVFoundation
import UIKit

/// Video processing service for keyboard extension
actor KeyboardVideoService {
    
    private let frameInterval: Double = 0.5
    private let maxFrames: Int = 20 // Lower for keyboard memory constraints
    
    func extractFrames(
        from videoURL: URL,
        progressHandler: @escaping (Double) -> Void
    ) async throws -> [UIImage] {
        let asset = AVURLAsset(url: videoURL)
        
        let duration = try await asset.load(.duration)
        let durationSeconds = CMTimeGetSeconds(duration)
        
        guard durationSeconds > 0 else {
            throw KeyboardVideoError.invalidVideo
        }
        
        let frameCount = min(maxFrames, Int(durationSeconds / frameInterval))
        var frameTimes: [CMTime] = []
        
        for i in 0..<frameCount {
            let seconds = Double(i) * frameInterval
            let time = CMTime(seconds: seconds, preferredTimescale: 600)
            frameTimes.append(time)
        }
        
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        generator.requestedTimeToleranceBefore = .zero
        generator.requestedTimeToleranceAfter = .zero
        generator.maximumSize = CGSize(width: 720, height: 1280) // Lower res for keyboard
        
        var images: [UIImage] = []
        
        for (index, time) in frameTimes.enumerated() {
            do {
                let cgImage = try generator.copyCGImage(at: time, actualTime: nil)
                let image = UIImage(cgImage: cgImage)
                images.append(image)
                
                let progress = Double(index + 1) / Double(frameTimes.count)
                progressHandler(progress)
            } catch {
                print("[KeyboardVideo] Failed to extract frame at \(CMTimeGetSeconds(time))s: \(error)")
            }
        }
        
        guard !images.isEmpty else {
            throw KeyboardVideoError.noFramesExtracted
        }
        
        return images
    }
    
    func extractTextFromVideo(
        at videoURL: URL,
        progressHandler: @escaping (Double, String) -> Void
    ) async throws -> String {
        progressHandler(0, "Extracting frames...")
        
        let frames = try await extractFrames(from: videoURL) { frameProgress in
            progressHandler(frameProgress * 0.5, "Extracting frames...")
        }
        
        progressHandler(0.5, "Running OCR...")
        
        let ocrService = KeyboardOCRService()
        let text = try await ocrService.recognizeText(from: frames) { ocrProgress in
            progressHandler(0.5 + (ocrProgress * 0.5), "Analyzing text...")
        }
        
        return text
    }
}

enum KeyboardVideoError: Error, LocalizedError {
    case invalidVideo
    case noFramesExtracted
    case processingFailed(Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidVideo:
            return "The video file is invalid"
        case .noFramesExtracted:
            return "Could not extract frames from video"
        case .processingFailed(let error):
            return "Processing failed: \(error.localizedDescription)"
        }
    }
}
