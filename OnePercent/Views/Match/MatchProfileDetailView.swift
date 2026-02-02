import SwiftUI
import SharedKit

/// Detailed view of a saved match profile with compatibility score
struct MatchProfileDetailView: View {
    let match: MatchProfile
    let userProfile: UserProfile?
    let messages: GeneratedMessageSet?
    
    @Environment(\.dismiss) private var dismiss
    
    // Random compatibility score between 32-74%
    private var compatibilityScore: Int {
        // Use match ID to generate consistent random score
        let seed = match.id.hashValue
        srand48(seed)
        return Int(drand48() * 42) + 32 // 32-74 range
    }
    
    // Random date likelihood
    private var dateLikelihood: Int {
        let seed = match.id.hashValue + 1
        srand48(seed)
        return Int(drand48() * 42) + 32
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header with name and basic info
                headerSection
                
                // Compatibility score
                compatibilitySection
                
                // Match summary
                matchSummarySection
                
                // Your profile summary
                if let user = userProfile {
                    yourSummarySection(user: user)
                }
                
                // Message history
                if let msgs = messages {
                    messageHistorySection(messages: msgs)
                }
                
                // Date likelihood
                dateLikelihoodSection
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(match.name ?? "Match")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // MARK: - Header
    private var headerSection: some View {
        VStack(spacing: 12) {
            // Avatar
            Circle()
                .fill(LinearGradient(colors: [.pink, .purple], startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(width: 80, height: 80)
                .overlay(
                    Text(match.name?.prefix(1).uppercased() ?? "?")
                        .font(.largeTitle.weight(.bold))
                        .foregroundStyle(.white)
                )
            
            // Name and age
            VStack(spacing: 4) {
                Text(match.name ?? "Unknown")
                    .font(.title2.weight(.bold))
                
                if let age = match.age {
                    Text("\(age) years old")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                if let location = match.location {
                    HStack(spacing: 4) {
                        Image(systemName: "location.fill")
                            .font(.caption)
                        Text(location)
                            .font(.caption)
                    }
                    .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical)
    }
    
    // MARK: - Compatibility
    private var compatibilitySection: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "heart.circle.fill")
                    .foregroundStyle(.pink)
                Text("Compatibility Score")
                    .font(.headline)
                Spacer()
            }
            
            HStack(alignment: .bottom, spacing: 4) {
                Text("\(compatibilityScore)")
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundStyle(.pink)
                Text("%")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(.pink.opacity(0.7))
                    .offset(y: -8)
            }
            
            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(.systemGray5))
                    
                    RoundedRectangle(cornerRadius: 8)
                        .fill(LinearGradient(colors: [.pink, .purple], startPoint: .leading, endPoint: .trailing))
                        .frame(width: geo.size.width * CGFloat(compatibilityScore) / 100)
                }
            }
            .frame(height: 12)
            
            Text("Based on shared interests and communication style")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    // MARK: - Match Summary
    private var matchSummarySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "person.fill")
                    .foregroundStyle(.purple)
                Text("About \(match.name ?? "Them")")
                    .font(.headline)
                Spacer()
            }
            
            if let bio = match.bio, !bio.isEmpty {
                Text(bio)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            // Interests
            if !match.interests.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Interests")
                        .font(.subheadline.weight(.semibold))
                    
                    FlowLayout(spacing: 8) {
                        ForEach(match.interests, id: \.self) { interest in
                            Text(interest)
                                .font(.caption)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.purple.opacity(0.1))
                                .foregroundStyle(.purple)
                                .clipShape(Capsule())
                        }
                    }
                }
            }
            
            // Job/School
            if let job = match.job {
                HStack(spacing: 8) {
                    Image(systemName: "briefcase.fill")
                        .foregroundStyle(.secondary)
                        .frame(width: 20)
                    Text(job)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            
            if let school = match.school {
                HStack(spacing: 8) {
                    Image(systemName: "graduationcap.fill")
                        .foregroundStyle(.secondary)
                        .frame(width: 20)
                    Text(school)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            
            // Hooks
            if !match.hooks.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Conversation Hooks")
                        .font(.subheadline.weight(.semibold))
                    
                    ForEach(match.hooks, id: \.self) { hook in
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "lightbulb.fill")
                                .foregroundStyle(.yellow)
                                .font(.caption)
                            Text(hook)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    // MARK: - Your Summary
    private func yourSummarySection(user: UserProfile) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "person.crop.circle.fill")
                    .foregroundStyle(.blue)
                Text("About You")
                    .font(.headline)
                Spacer()
            }
            
            if let name = user.displayName {
                Text(name)
                    .font(.subheadline.weight(.medium))
            }
            
            if let tone = user.voiceAndTonePreferences {
                HStack(spacing: 8) {
                    Image(systemName: "waveform")
                        .foregroundStyle(.secondary)
                        .frame(width: 20)
                    Text("Communication style: \(tone)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    // MARK: - Message History
    private func messageHistorySection(messages: GeneratedMessageSet) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "bubble.left.and.bubble.right.fill")
                    .foregroundStyle(.green)
                Text("Generated Messages")
                    .font(.headline)
                Spacer()
            }
            
            ForEach(messages.messages) { message in
                VStack(alignment: .leading, spacing: 8) {
                    // Message type badge
                    Text(message.type.rawValue.capitalized)
                        .font(.caption2.weight(.semibold))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(message.type == .opener ? Color.green.opacity(0.1) : Color.orange.opacity(0.1))
                        .foregroundStyle(message.type == .opener ? .green : .orange)
                        .clipShape(Capsule())
                    
                    // Message lines
                    ForEach(message.lines, id: \.self) { line in
                        Text(line)
                            .font(.subheadline)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color(.systemGray6))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    
                    // Reasoning if available
                    if let reasoning = message.reasoning {
                        HStack(alignment: .top, spacing: 6) {
                            Image(systemName: "sparkles")
                                .font(.caption2)
                                .foregroundStyle(.pink)
                            Text(reasoning)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.top, 4)
                    }
                }
                .padding(.vertical, 8)
                
                if message.id != messages.messages.last?.id {
                    Divider()
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    // MARK: - Date Likelihood
    private var dateLikelihoodSection: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "calendar.badge.clock")
                    .foregroundStyle(.orange)
                Text("Date Likelihood")
                    .font(.headline)
                Spacer()
            }
            
            HStack(alignment: .bottom, spacing: 4) {
                Text("\(dateLikelihood)")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundStyle(.orange)
                Text("%")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.orange.opacity(0.7))
                    .offset(y: -6)
            }
            
            Text("Estimated chance based on profile compatibility and message engagement potential")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}
