import SwiftUI

struct ControlsRow: View {
    let onNextKeyboard: () -> Void
    let onDeleteBackward: () -> Void
    let onOpenApp: () -> Void
    let hasFullAccess: Bool
    
    var body: some View {
        HStack(spacing: 0) {
            // Globe (next keyboard) button
            KeyboardButton(
                icon: "globe",
                action: onNextKeyboard
            )
            
            Spacer()
            
            // Open app button
            Button(action: onOpenApp) {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.up.right.square")
                        .font(.system(size: 14))
                    Text("Open App")
                        .font(.system(size: 12, weight: .medium))
                }
                .foregroundStyle(.pink)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.pink.opacity(0.1))
                .clipShape(Capsule())
            }
            .buttonStyle(.plain)
            
            Spacer()
            
            // Backspace button
            KeyboardButton(
                icon: "delete.left",
                action: onDeleteBackward
            )
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }
}

struct KeyboardButton: View {
    let icon: String
    let action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundStyle(.primary)
                .frame(width: 44, height: 36)
                .background(isPressed ? Color(.systemGray4) : Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }
}

#Preview {
    ControlsRow(
        onNextKeyboard: {},
        onDeleteBackward: {},
        onOpenApp: {},
        hasFullAccess: true
    )
    .background(Color(.systemBackground))
}
