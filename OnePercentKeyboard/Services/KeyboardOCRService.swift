import Foundation
import Vision
import UIKit

/// OCR service for keyboard extension
actor KeyboardOCRService {
    
    private let maxImageDimension: CGFloat = 1500
    
    func recognizeText(
        from images: [UIImage],
        progressHandler: @escaping (Double) -> Void
    ) async throws -> String {
        guard !images.isEmpty else {
            throw KeyboardOCRError.noImages
        }
        
        var allTexts: [String] = []
        let totalImages = Double(images.count)
        
        for (index, image) in images.enumerated() {
            let scaledImage = scaleImage(image)
            let text = try await recognizeText(from: scaledImage)
            allTexts.append(text)
            
            let progress = Double(index + 1) / totalImages
            progressHandler(progress)
        }
        
        return mergeAndDeduplicate(texts: allTexts)
    }
    
    private func recognizeText(from image: UIImage) async throws -> String {
        guard let cgImage = image.cgImage else {
            throw KeyboardOCRError.invalidImage
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: KeyboardOCRError.visionError(error))
                    return
                }
                
                guard let observations = request.results as? [VNRecognizedTextObservation] else {
                    continuation.resume(returning: "")
                    return
                }
                
                let text = observations.compactMap { observation in
                    observation.topCandidates(1).first?.string
                }.joined(separator: "\n")
                
                continuation.resume(returning: text)
            }
            
            request.recognitionLevel = .accurate
            request.recognitionLanguages = ["en-US"]
            request.usesLanguageCorrection = true
            
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: KeyboardOCRError.visionError(error))
            }
        }
    }
    
    private func scaleImage(_ image: UIImage) -> UIImage {
        let size = image.size
        guard size.width > maxImageDimension || size.height > maxImageDimension else {
            return image
        }
        
        let ratio = min(maxImageDimension / size.width, maxImageDimension / size.height)
        let newSize = CGSize(width: size.width * ratio, height: size.height * ratio)
        
        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
    
    private func mergeAndDeduplicate(texts: [String]) -> String {
        var allLines: [String] = []
        for text in texts {
            let lines = text.components(separatedBy: .newlines)
                .map { $0.trimmingCharacters(in: .whitespaces) }
                .filter { !$0.isEmpty }
            allLines.append(contentsOf: lines)
        }
        
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
    
    private func jaccardSimilarity(_ s1: String, _ s2: String) -> Double {
        let tokens1 = Set(s1.lowercased().components(separatedBy: .whitespaces))
        let tokens2 = Set(s2.lowercased().components(separatedBy: .whitespaces))
        
        guard !tokens1.isEmpty || !tokens2.isEmpty else { return 1.0 }
        
        let intersection = tokens1.intersection(tokens2).count
        let union = tokens1.union(tokens2).count
        
        return Double(intersection) / Double(union)
    }
}

enum KeyboardOCRError: Error, LocalizedError {
    case noImages
    case invalidImage
    case visionError(Error)
    
    var errorDescription: String? {
        switch self {
        case .noImages:
            return "No images provided"
        case .invalidImage:
            return "Could not process image"
        case .visionError(let error):
            return "Vision error: \(error.localizedDescription)"
        }
    }
}
