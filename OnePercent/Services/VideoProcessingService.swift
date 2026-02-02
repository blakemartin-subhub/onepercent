import Foundation
import AVFoundation
import UIKit

/// Service for extracting frames from screen recordings
actor VideoProcessingService {
    
    /// Time interval between frame extractions (in seconds)
    private let frameInterval: Double = 0.5
    
    /// Maximum number of frames to extract
    private let maxFrames: Int = 30
    
    /// Extract key frames from a video file
    func extractFrames(
        from videoURL: URL,
        progressHandler: @escaping (Double) -> Void
    ) async throws -> [UIImage] {
        let asset = AVURLAsset(url: videoURL)
        
        // Get video duration
        let duration = try await asset.load(.duration)
        let durationSeconds = CMTimeGetSeconds(duration)
        
        guard durationSeconds > 0 else {
            throw VideoProcessingError.invalidVideo
        }
        
        // Calculate frame times
        let frameCount = min(maxFrames, Int(durationSeconds / frameInterval))
        var frameTimes: [CMTime] = []
        
        for i in 0..<frameCount {
            let seconds = Double(i) * frameInterval
            let time = CMTime(seconds: seconds, preferredTimescale: 600)
            frameTimes.append(time)
        }
        
        // Create image generator
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        generator.requestedTimeToleranceBefore = .zero
        generator.requestedTimeToleranceAfter = .zero
        
        // Set max size to reduce memory usage
        generator.maximumSize = CGSize(width: 1080, height: 1920)
        
        // Extract frames
        var images: [UIImage] = []
        
        for (index, time) in frameTimes.enumerated() {
            do {
                let cgImage = try generator.copyCGImage(at: time, actualTime: nil)
                let image = UIImage(cgImage: cgImage)
                images.append(image)
                
                // Update progress
                let progress = Double(index + 1) / Double(frameTimes.count)
                progressHandler(progress)
            } catch {
                // Skip frames that fail to extract
                print("Failed to extract frame at \(CMTimeGetSeconds(time))s: \(error)")
            }
        }
        
        guard !images.isEmpty else {
            throw VideoProcessingError.noFramesExtracted
        }
        
        return images
    }
    
    /// Extract frames and run OCR, returning merged text
    func extractTextFromVideo(
        at videoURL: URL,
        progressHandler: @escaping (Double, String) -> Void
    ) async throws -> String {
        // Phase 1: Extract frames (0-50%)
        progressHandler(0, "Extracting frames...")
        
        let frames = try await extractFrames(from: videoURL) { frameProgress in
            progressHandler(frameProgress * 0.5, "Extracting frames...")
        }
        
        // Phase 2: OCR on frames (50-100%)
        progressHandler(0.5, "Running OCR...")
        
        let ocrService = OCRService()
        let text = try await ocrService.recognizeText(from: frames) { ocrProgress in
            progressHandler(0.5 + (ocrProgress * 0.5), "Analyzing text...")
        }
        
        return text
    }
}

enum VideoProcessingError: Error, LocalizedError {
    case invalidVideo
    case noFramesExtracted
    case processingFailed(Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidVideo:
            return "The video file is invalid or corrupted"
        case .noFramesExtracted:
            return "Could not extract any frames from the video"
        case .processingFailed(let error):
            return "Video processing failed: \(error.localizedDescription)"
        }
    }
}
