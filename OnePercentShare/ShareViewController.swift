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
        print("[ShareExt] Saving video from: \(sourceURL)")
        guard let inbox = storage.shareInboxDirectory else {
            print("[ShareExt] ERROR: No share inbox directory")
            return nil
        }
        print("[ShareExt] Share inbox directory: \(inbox)")
        
        let fileName = "\(UUID().uuidString).mp4"
        let destURL = inbox.appendingPathComponent(fileName)
        
        do {
            // Copy video to app group container
            if FileManager.default.fileExists(atPath: destURL.path) {
                try FileManager.default.removeItem(at: destURL)
            }
            try FileManager.default.copyItem(at: sourceURL, to: destURL)
            print("[ShareExt] Video saved successfully to: \(destURL)")
            return fileName
        } catch {
            print("[ShareExt] Failed to save video: \(error)")
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
        print("[ShareExt] saveManifestAndOpenApp - images: \(imageFiles.count), video: \(videoFile ?? "none")")
        
        guard let inbox = storage.shareInboxDirectory else {
            print("[ShareExt] ERROR: No inbox directory for manifest")
            completeWithError()
            return
        }
        
        // Create manifest
        let manifest = ShareInboxManifest(imageFiles: imageFiles, videoFile: videoFile)
        let manifestURL = inbox.appendingPathComponent(AppGroupConstants.shareInboxManifestFile)
        
        do {
            try storage.save(manifest, to: manifestURL)
            print("[ShareExt] Manifest saved to: \(manifestURL)")
        } catch {
            print("[ShareExt] Failed to save manifest: \(error)")
            completeWithError()
            return
        }
        
        // Open main app
        openMainApp()
        
        // Complete extension
        completeWithSuccess()
    }
    
    private func openMainApp() {
        guard let url = URL(string: "onepercent://import") else {
            print("[ShareExt] ERROR: Could not create URL")
            return
        }
        
        print("[ShareExt] Attempting to open URL: \(url)")
        
        // Use responder chain to open URL
        var responder: UIResponder? = self
        while responder != nil {
            if let application = responder as? UIApplication {
                print("[ShareExt] Found UIApplication, opening URL...")
                application.open(url, options: [:], completionHandler: nil)
                return
            }
            responder = responder?.next
        }
        
        // Alternative: Use selector
        print("[ShareExt] UIApplication not found, trying selector method...")
        let selector = NSSelectorFromString("openURL:")
        responder = self
        while responder != nil {
            if responder!.responds(to: selector) {
                print("[ShareExt] Found responder with openURL selector")
                responder!.perform(selector, with: url)
                return
            }
            responder = responder?.next
        }
        
        print("[ShareExt] WARNING: Could not find way to open main app")
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
