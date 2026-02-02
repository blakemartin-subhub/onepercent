import UIKit
import SwiftUI

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        // Handle URL if app was launched with one
        if let urlContext = connectionOptions.urlContexts.first {
            handleURL(urlContext.url)
        }
    }
    
    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        guard let url = URLContexts.first?.url else { return }
        handleURL(url)
    }
    
    private func handleURL(_ url: URL) {
        // Handle deep links from share extension
        // onepercent://import triggers the import flow
        guard url.scheme == "onepercent" else { return }
        
        if url.host == "import" {
            NotificationCenter.default.post(
                name: .didReceiveShareExtensionImages,
                object: nil
            )
        }
    }
}

extension Notification.Name {
    static let didReceiveShareExtensionImages = Notification.Name("didReceiveShareExtensionImages")
}
