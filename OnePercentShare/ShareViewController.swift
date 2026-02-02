import UIKit
import Social
import UniformTypeIdentifiers
import SharedKit

/// Share extension for receiving screenshots and screen recordings from Photos
class ShareViewController: UIViewController {
    
    private let storage = AppGroupStorage.shared
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Process shared items
        processSharedItems()
    }
    
    private func processSharedItems() {
        guard let extensionContext = extensionContext,
              let inputItems = extensionContext.inputItems as? [NSExtensionItem] else {
            completeWithError()
            return
        }
        
        var imageURLs: [String] = []
        var videoURL: String?
        let group = DispatchGroup()
        
        for item in inputItems {
            guard let attachments = item.attachments else { continue }
            
            for attachment in attachments {
                // Handle videos (screen recordings)
                if attachment.hasItemConformingToTypeIdentifier(UTType.movie.identifier) {
                    group.enter()
                    
                    attachment.loadItem(forTypeIdentifier: UTType.movie.identifier, options: nil) { [weak self] item, error in
                        defer { group.leave() }
                        
                        guard error == nil, let url = item as? URL else { return }
                        
                        if let savedFileName = self?.saveVideo(from: url) {
                            DispatchQueue.main.async {
                                videoURL = savedFileName
                            }
                        }
                    }
                }
                // Handle images (screenshots)
                else if attachment.hasItemConformingToTypeIdentifier(UTType.image.identifier) {
                    group.enter()
                    
                    attachment.loadItem(forTypeIdentifier: UTType.image.identifier, options: nil) { [weak self] item, error in
                        defer { group.leave() }
                        
                        guard error == nil else { return }
                        
                        var imageData: Data?
                        
                        if let url = item as? URL {
                            imageData = try? Data(contentsOf: url)
                        } else if let image = item as? UIImage {
                            imageData = image.jpegData(compressionQuality: 0.8)
                        } else if let data = item as? Data {
                            imageData = data
                        }
                        
                        if let data = imageData,
                           let savedFileName = self?.saveImage(data: data) {
                            DispatchQueue.main.async {
                                imageURLs.append(savedFileName)
                            }
                        }
                    }
                }
            }
        }
        
        group.notify(queue: .main) { [weak self] in
            if let video = videoURL {
                // Video takes priority - it's a screen recording
                self?.saveManifestAndOpenApp(imageFiles: [], videoFile: video)
            } else if !imageURLs.isEmpty {
                self?.saveManifestAndOpenApp(imageFiles: imageURLs, videoFile: nil)
            } else {
                self?.completeWithError()
            }
        }
    }
    
    private func saveVideo(from sourceURL: URL) -> String? {
        guard let inbox = storage.shareInboxDirectory else { return nil }
        
        let fileName = "\(UUID().uuidString).mp4"
        let destURL = inbox.appendingPathComponent(fileName)
        
        do {
            // Copy video to app group container
            if FileManager.default.fileExists(atPath: destURL.path) {
                try FileManager.default.removeItem(at: destURL)
            }
            try FileManager.default.copyItem(at: sourceURL, to: destURL)
            return fileName
        } catch {
            print("Failed to save video: \(error)")
            return nil
        }
    }
    
    private func saveImage(data: Data) -> String? {
        guard let inbox = storage.shareInboxDirectory else { return nil }
        
        let fileName = "\(UUID().uuidString).jpg"
        let fileURL = inbox.appendingPathComponent(fileName)
        
        do {
            try data.write(to: fileURL)
            return fileName
        } catch {
            print("Failed to save image: \(error)")
            return nil
        }
    }
    
    private func saveManifestAndOpenApp(imageFiles: [String], videoFile: String?) {
        guard let inbox = storage.shareInboxDirectory else {
            completeWithError()
            return
        }
        
        // Create manifest
        let manifest = ShareInboxManifest(imageFiles: imageFiles, videoFile: videoFile)
        let manifestURL = inbox.appendingPathComponent(AppGroupConstants.shareInboxManifestFile)
        
        do {
            try storage.save(manifest, to: manifestURL)
        } catch {
            print("Failed to save manifest: \(error)")
            completeWithError()
            return
        }
        
        // Open main app
        openMainApp()
        
        // Complete extension
        completeWithSuccess()
    }
    
    private func openMainApp() {
        guard let url = URL(string: "onepercent://import") else { return }
        
        // Use responder chain to open URL
        var responder: UIResponder? = self
        while responder != nil {
            if let application = responder as? UIApplication {
                application.open(url, options: [:], completionHandler: nil)
                return
            }
            responder = responder?.next
        }
        
        // Alternative: Use selector
        let selector = NSSelectorFromString("openURL:")
        responder = self
        while responder != nil {
            if responder!.responds(to: selector) {
                responder!.perform(selector, with: url)
                return
            }
            responder = responder?.next
        }
    }
    
    private func completeWithSuccess() {
        extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
    }
    
    private func completeWithError() {
        let error = NSError(
            domain: "com.onepercent.share",
            code: -1,
            userInfo: [NSLocalizedDescriptionKey: "Failed to process shared images"]
        )
        extensionContext?.cancelRequest(withError: error)
    }
}
