import SwiftUI

struct OCRProgressView: View {
    let progress: Double
    
    @State private var animatedProgress: Double = 0
    @State private var currentMessage = 0
    
    private let messages = [
        "Scanning screenshots...",
        "Extracting text...",
        "Analyzing profile...",
        "Finding conversation hooks...",
        "Almost done..."
    ]
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            // Animated icon
            ZStack {
                Circle()
                    .stroke(Brand.accentLight, lineWidth: 8)
                    .frame(width: 120, height: 120)
                
                Circle()
                    .trim(from: 0, to: animatedProgress)
                    .stroke(
                        Brand.gradient,
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .frame(width: 120, height: 120)
                    .rotationEffect(.degrees(-90))
                
                Image(systemName: "sparkles")
                    .font(.system(size: 40))
                    .foregroundStyle(Brand.accent)
            }
            
            VStack(spacing: 12) {
                Text("Processing")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundStyle(Brand.textPrimary)
                
                Text(messages[min(currentMessage, messages.count - 1)])
                    .font(.subheadline)
                    .foregroundStyle(Brand.textSecondary)
                    .animation(.easeInOut, value: currentMessage)
            }
            
            // Progress bar
            VStack(spacing: 8) {
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Brand.accentLight)
                            .frame(height: 8)
                        
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Brand.buttonGradient)
                            .frame(width: geometry.size.width * animatedProgress, height: 8)
                    }
                }
                .frame(height: 8)
                
                Text("\(Int(animatedProgress * 100))%")
                    .font(.caption)
                    .foregroundStyle(Brand.textSecondary)
            }
            .padding(.horizontal, 60)
            
            Spacer()
            Spacer()
        }
        .background(Brand.background)
        .onChange(of: progress) { _, newValue in
            withAnimation(.easeInOut(duration: 0.3)) {
                animatedProgress = newValue
            }
            updateMessage(for: newValue)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.3)) {
                animatedProgress = progress
            }
        }
    }
    
    private func updateMessage(for progress: Double) {
        let index = Int(progress * Double(messages.count - 1))
        if index != currentMessage {
            withAnimation {
                currentMessage = index
            }
        }
    }
}

#Preview {
    OCRProgressView(progress: 0.6)
}
