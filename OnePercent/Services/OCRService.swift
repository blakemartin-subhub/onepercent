import Foundation
import Vision
import UIKit

/// Service for performing OCR on images using Apple's Vision framework
actor OCRService {
    
    /// Maximum dimension for image scaling (to reduce memory usage)
    private let maxImageDimension: CGFloat = 2000
    
    /// Recognize text from multiple images and merge results
    func recognizeText(
        from images: [UIImage],
        progressHandler: @escaping (Double) -> Void
    ) async throws -> String {
        guard !images.isEmpty else {
            throw OCRError.noImages
        }
        
        var allTexts: [String] = []
        let totalImages = Double(images.count)
        
        for (index, image) in images.enumerated() {
            // Scale image to reduce memory
            let scaledImage = scaleImage(image)
            
            // Perform OCR
            let text = try await recognizeText(from: scaledImage)
            allTexts.append(text)
            
            // Update progress
            let progress = Double(index + 1) / totalImages
            progressHandler(progress)
        }
        
        // Merge and deduplicate
        let mergedText = mergeAndDeduplicate(texts: allTexts)
        return mergedText
    }
    
    /// Recognize text from a single image
    private func recognizeText(from image: UIImage) async throws -> String {
        guard let cgImage = image.cgImage else {
            throw OCRError.invalidImage
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: OCRError.visionError(error))
                    return
                }
                
                guard let observations = request.results as? [VNRecognizedTextObservation] else {
                    continuation.resume(returning: "")
                    return
                }
                
                // Extract text from observations
                let text = observations.compactMap { observation in
                    observation.topCandidates(1).first?.string
                }.joined(separator: "\n")
                
                continuation.resume(returning: text)
            }
            
            // Configure for accuracy
            request.recognitionLevel = .accurate
            request.recognitionLanguages = ["en-US"]
            request.usesLanguageCorrection = true
            
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: OCRError.visionError(error))
            }
        }
    }
    
    /// Scale image to reduce memory usage
    private func scaleImage(_ image: UIImage) -> UIImage {
        let size = image.size
        
        // Check if scaling is needed
        guard size.width > maxImageDimension || size.height > maxImageDimension else {
            return image
        }
        
        // Calculate new size
        let ratio = min(maxImageDimension / size.width, maxImageDimension / size.height)
        let newSize = CGSize(width: size.width * ratio, height: size.height * ratio)
        
        // Scale image
        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
    
    /// Merge multiple text blocks and remove duplicates
    private func mergeAndDeduplicate(texts: [String]) -> String {
        // Split all texts into lines
        var allLines: [String] = []
        for text in texts {
            let lines = text.components(separatedBy: .newlines)
                .map { $0.trimmingCharacters(in: .whitespaces) }
                .filter { !$0.isEmpty }
            allLines.append(contentsOf: lines)
        }
        
        // Deduplicate using similarity
        var uniqueLines: [String] = []
        for line in allLines {
            let isDuplicate = uniqueLines.contains { existingLine in
                jaccardSimilarity(line, existingLine) > 0.8
            }
            if !isDuplicate {
                uniqueLines.append(line)
            }
        }
        
        return uniqueLines.joined(separator: "\n")
    }
    
    /// Calculate Jaccard similarity between two strings
    private func jaccardSimilarity(_ s1: String, _ s2: String) -> Double {
        let tokens1 = Set(s1.lowercased().components(separatedBy: .whitespaces))
        let tokens2 = Set(s2.lowercased().components(separatedBy: .whitespaces))
        
        guard !tokens1.isEmpty || !tokens2.isEmpty else { return 1.0 }
        
        let intersection = tokens1.intersection(tokens2).count
        let union = tokens1.union(tokens2).count
        
        return Double(intersection) / Double(union)
    }
}

enum OCRError: Error, LocalizedError {
    case noImages
    case invalidImage
    case visionError(Error)
    
    var errorDescription: String? {
        switch self {
        case .noImages:
            return "No images provided for OCR"
        case .invalidImage:
            return "Could not process image"
        case .visionError(let error):
            return "Vision error: \(error.localizedDescription)"
        }
    }
}
