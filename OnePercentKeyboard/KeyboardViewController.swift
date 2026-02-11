import UIKit
import SwiftUI
import SharedKit

/// Main keyboard view controller
class KeyboardViewController: UIInputViewController {
    
    // MARK: - Properties
    
    private var hostingController: UIHostingController<KeyboardMainView>?
    private var heightConstraint: NSLayoutConstraint?
    private let store = MatchStore.shared
    
    /// Check if keyboard has full access (for networking)
    private var keyboardHasFullAccess: Bool {
        // In iOS 11+, we can check if the keyboard has open access
        return self.hasFullAccess
    }
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupKeyboardView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        refreshData()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        hostingController?.view.frame = view.bounds
    }
    
    // MARK: - Setup
    
    private func setupKeyboardView() {
        // Create SwiftUI view
        let keyboardView = KeyboardMainView(
            onInsertText: { [weak self] text in
                self?.insertText(text)
            },
            onDeleteBackward: { [weak self] in
                self?.deleteBackward()
            },
            onNextKeyboard: { [weak self] in
                self?.advanceToNextInputMode()
            },
            onOpenApp: { [weak self] in
                self?.openMainApp()
            },
            onRequestHeight: { [weak self] height in
                self?.updateKeyboardHeight(height)
            }
        )
        
        // Embed in hosting controller
        let hostingController = UIHostingController(rootView: keyboardView)
        hostingController.view.backgroundColor = .clear
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        
        addChild(hostingController)
        view.addSubview(hostingController.view)
        hostingController.didMove(toParent: self)
        
        // Set constraints
        NSLayoutConstraint.activate([
            hostingController.view.topAnchor.constraint(equalTo: view.topAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            hostingController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])
        
        self.hostingController = hostingController
        
        // Set keyboard height (380pt — tighter fit for direction + line mode + text field + internal keyboard)
        let heightConstraint = view.heightAnchor.constraint(equalToConstant: 380)
        heightConstraint.priority = .defaultHigh
        heightConstraint.isActive = true
        self.heightConstraint = heightConstraint
    }
    
    private func refreshData() {
        // Data refresh happens in SwiftUI view via MatchStore
    }
    
    private func updateKeyboardHeight(_ height: CGFloat) {
        guard let heightConstraint = heightConstraint else { return }
        guard heightConstraint.constant != height else { return }
        
        UIView.animate(withDuration: 0.25, delay: 0, options: .curveEaseInOut) {
            heightConstraint.constant = height
            self.view.superview?.layoutIfNeeded()
        }
    }
    
    // MARK: - Text Input Actions
    
    private func insertText(_ text: String) {
        textDocumentProxy.insertText(text)
        
        // Add trailing space if configured
        if !text.hasSuffix(" ") && !text.hasSuffix("\n") {
            textDocumentProxy.insertText(" ")
        }
        
        // Haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
    
    private func deleteBackward() {
        textDocumentProxy.deleteBackward()
    }
    
    // MARK: - Navigation
    
    private func openMainApp() {
        // Open main app via URL scheme
        guard let url = URL(string: "onepercent://") else {
            print("[Keyboard] Failed to create URL")
            return
        }
        
        print("[Keyboard] Attempting to open main app via URL: \(url)")
        
        // Method 1: Try using UIApplication.shared via shared container
        // Note: This requires the keyboard to have "RequestsOpenAccess" set to YES in Info.plist
        if let sharedApplication = UIApplication.value(forKey: "sharedApplication") as? UIApplication {
            print("[Keyboard] Found UIApplication, attempting to open...")
            sharedApplication.open(url, options: [:]) { success in
                print("[Keyboard] Open URL result: \(success)")
            }
            return
        }
        
        print("[Keyboard] UIApplication not available, trying responder chain...")
        
        // Method 2: Use responder chain (fallback)
        let selector = NSSelectorFromString("openURL:")
        var responder: UIResponder? = self
        
        while responder != nil {
            if responder!.responds(to: selector) {
                print("[Keyboard] Found responder with openURL, attempting...")
                responder!.perform(selector, with: url)
                return
            }
            responder = responder?.next
        }
        
        print("[Keyboard] WARNING: Could not find way to open main app")
    }
}
