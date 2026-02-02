import UIKit
import SwiftUI
import SharedKit

/// Main keyboard view controller
class KeyboardViewController: UIInputViewController {
    
    // MARK: - Properties
    
    private var hostingController: UIHostingController<KeyboardMainView>?
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
        
        // Set keyboard height
        let heightConstraint = view.heightAnchor.constraint(equalToConstant: 280)
        heightConstraint.priority = .defaultHigh
        heightConstraint.isActive = true
    }
    
    private func refreshData() {
        // Data refresh happens in SwiftUI view via MatchStore
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
        guard let url = URL(string: "onepercent://") else { return }
        
        // Use the shared extension context to open URL
        let selector = NSSelectorFromString("openURL:")
        var responder: UIResponder? = self
        
        while responder != nil {
            if responder!.responds(to: selector) {
                responder!.perform(selector, with: url)
                return
            }
            responder = responder?.next
        }
    }
}
