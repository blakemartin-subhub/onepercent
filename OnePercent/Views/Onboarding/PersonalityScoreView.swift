import SwiftUI
import SharedKit

// MARK: - PersonalityScoreView

struct PersonalityScoreView: View {
    let userName: String
    let onComplete: () -> Void
    
    // MARK: - Animation State
    
    @State private var phase: AnimationPhase = .analyzing
    
    // Phase 1: Analyzing
    @State private var analyzeOpacity: Double = 0
    @State private var pulseScale: CGFloat = 1.0
    @State private var spinAngle: Double = 0
    
    // Phase 2: Score wheel
    @State private var wheelProgress: CGFloat = 0
    @State private var displayedScore: Int = 0
    @State private var wheelVisible = false
    @State private var scoreLabelVisible = false
    
    // Phase 3: Keyboard Ready fizzle
    @State private var keyboardReadyVisible = false
    @State private var keyboardReadyScale: CGFloat = 0.3
    
    // Phase 4: Welcome text
    @State private var welcomeVisible = false
    @State private var welcomeOffset: CGFloat = 20
    
    // Phase 5: Button
    @State private var buttonVisible = false
    
    // Score
    private let targetScore = Int.random(in: 83...97)
    
    // MARK: - Animation Phase
    
    private enum AnimationPhase {
        case analyzing
        case scoring
        case complete
    }
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            ZStack {
                // Phase 1: Analyzing spinner
                if phase == .analyzing {
                    analyzingView
                        .opacity(analyzeOpacity)
                        .transition(.opacity.combined(with: .scale(scale: 0.9)))
                }
                
                // Phase 2+: Score & results
                if phase != .analyzing {
                    resultsView
                        .transition(.opacity.combined(with: .scale(scale: 0.95)))
                }
            }
            
            Spacer()
            
            // Get Started button
            if buttonVisible {
                Button(action: onComplete) {
                    HStack(spacing: 8) {
                        Text("Get Started")
                            .font(.body.weight(.semibold))
                        Image(systemName: "arrow.right")
                            .font(.body.weight(.semibold))
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(Brand.accent)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 50)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .background(Brand.background.ignoresSafeArea())
        .onAppear { startSequence() }
    }
}

// MARK: - Subviews

private extension PersonalityScoreView {
    
    // MARK: Analyzing View
    
    var analyzingView: some View {
        VStack(spacing: 28) {
            // Greeting
            Text("Hey \(userName)")
                .font(.title2.weight(.bold))
                .foregroundStyle(Brand.textPrimary)
            
            ZStack {
                // Pulsing ring
                Circle()
                    .stroke(Brand.accent.opacity(0.15), lineWidth: 4)
                    .frame(width: 90, height: 90)
                
                Circle()
                    .stroke(Brand.accent.opacity(0.3), lineWidth: 3)
                    .frame(width: 90, height: 90)
                    .scaleEffect(pulseScale)
                    .opacity(2.0 - Double(pulseScale))
                
                // Spinning arc
                Circle()
                    .trim(from: 0, to: 0.25)
                    .stroke(Brand.accent, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .frame(width: 90, height: 90)
                    .rotationEffect(.degrees(spinAngle))
            }
            
            VStack(spacing: 8) {
                Text("Analyzing your profile")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(Brand.textPrimary)
                
                Text("Optimizing message intelligence")
                    .font(.subheadline)
                    .foregroundStyle(Brand.textSecondary)
            }
        }
    }
    
    // MARK: Results View
    
    var resultsView: some View {
        VStack(spacing: 0) {
            // Score wheel
            scoreWheel
                .opacity(wheelVisible ? 1 : 0)
                .scaleEffect(wheelVisible ? 1 : 0.7)
            
            Spacer().frame(height: 16)
            
            // "Personality Optimization Score" label
            Text("Personality\nOptimization Score")
                .font(.footnote.weight(.medium))
                .foregroundStyle(Brand.textSecondary)
                .multilineTextAlignment(.center)
                .opacity(scoreLabelVisible ? 1 : 0)
            
            Spacer().frame(height: 32)
            
            // Keyboard Ready badge
            keyboardReadyBadge
                .opacity(keyboardReadyVisible ? 1 : 0)
                .scaleEffect(keyboardReadyVisible ? 1 : keyboardReadyScale)
            
            Spacer().frame(height: 28)
            
            // Welcome text -- large, bold, slow fade
            Text("Welcome To The One Percent")
                .font(.title.weight(.bold))
                .foregroundStyle(Brand.textPrimary)
                .multilineTextAlignment(.center)
                .opacity(welcomeVisible ? 1 : 0)
                .offset(y: welcomeOffset)
        }
        .padding(.horizontal, 24)
    }
    
    // MARK: Score Wheel
    
    var scoreWheel: some View {
        ZStack {
            // Background track
            Circle()
                .stroke(Brand.accent.opacity(0.1), style: StrokeStyle(lineWidth: 14, lineCap: .round))
                .frame(width: 200, height: 200)
            
            // Animated progress arc
            Circle()
                .trim(from: 0, to: wheelProgress)
                .stroke(Brand.accent, style: StrokeStyle(lineWidth: 14, lineCap: .round))
                .frame(width: 200, height: 200)
                .rotationEffect(.degrees(-90))
            
            // Score number
            VStack(spacing: 2) {
                Text("\(displayedScore)")
                    .font(.system(size: 56, weight: .bold, design: .rounded))
                    .foregroundStyle(Brand.textPrimary)
                    .contentTransition(.numericText())
                
                Text("/ 100")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Brand.textSecondary)
            }
        }
    }
    
    // MARK: Keyboard Ready Badge
    
    var keyboardReadyBadge: some View {
        HStack(spacing: 10) {
            Image(systemName: "keyboard.fill")
                .font(.title3)
                .foregroundStyle(.white)
            
            Text("Keyboard Ready")
                .font(.headline.weight(.bold))
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 28)
        .padding(.vertical, 14)
        .background(Brand.accent)
        .clipShape(Capsule())
    }
}

// MARK: - Animation Sequence

private extension PersonalityScoreView {
    
    func startSequence() {
        // Fade in analyzing view
        withAnimation(.easeOut(duration: 0.6)) {
            analyzeOpacity = 1
        }
        
        // Start pulse animation
        withAnimation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true)) {
            pulseScale = 1.6
        }
        
        // Start spin animation
        withAnimation(.linear(duration: 1.2).repeatForever(autoreverses: false)) {
            spinAngle = 360
        }
        
        // Phase 2: Transition to score wheel after 2.5s
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            withAnimation(.easeInOut(duration: 0.5)) {
                phase = .scoring
            }
            
            // Show wheel
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.75)) {
                    wheelVisible = true
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    withAnimation(.easeOut(duration: 0.4)) {
                        scoreLabelVisible = true
                    }
                }
                
                animateScore()
            }
        }
    }
    
    func animateScore() {
        let targetProgress = CGFloat(targetScore) / 100.0
        
        // Animate the wheel arc
        withAnimation(.easeOut(duration: 2.0)) {
            wheelProgress = targetProgress
        }
        
        // Animate the counter number
        animateCounter(to: targetScore, duration: 2.0)
        
        // Phase 3: Keyboard Ready fizzle (after wheel completes)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                keyboardReadyVisible = true
                keyboardReadyScale = 1.0
            }
            
            // Phase 4: Welcome text -- SLOW fade in (1.2s duration)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                withAnimation(.easeOut(duration: 1.2)) {
                    welcomeVisible = true
                    welcomeOffset = 0
                    phase = .complete
                }
                
                // Phase 5: Button (after welcome finishes)
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                        buttonVisible = true
                    }
                }
            }
        }
    }
    
    func animateCounter(to target: Int, duration: TimeInterval) {
        let steps = 40
        let interval = duration / Double(steps)
        
        for i in 1...steps {
            DispatchQueue.main.asyncAfter(deadline: .now() + interval * Double(i)) {
                let progress = easeOutCubic(Double(i) / Double(steps))
                let value = Int(Double(target) * progress)
                withAnimation(.none) {
                    displayedScore = min(value, target)
                }
            }
        }
    }
    
    func easeOutCubic(_ t: Double) -> Double {
        let p = t - 1
        return p * p * p + 1
    }
}

#Preview {
    PersonalityScoreView(userName: "Blake", onComplete: {})
}
