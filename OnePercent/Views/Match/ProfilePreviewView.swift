import SwiftUI
import SharedKit

struct ProfilePreviewView: View {
    @Binding var profile: MatchProfile
    let onContinue: () -> Void
    let onCancel: () -> Void
    
    @State private var editedName: String = ""
    @State private var editedAge: String = ""
    @State private var editedBio: String = ""
    @State private var editedJob: String = ""
    @State private var editedSchool: String = ""
    @State private var editedLocation: String = ""
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [.pink.opacity(0.3), .purple.opacity(0.3)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 80, height: 80)
                        
                        Text((editedName.isEmpty ? "?" : editedName).prefix(1).uppercased())
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundStyle(.pink)
                    }
                    
                    Text("Review Extracted Profile")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 20)
                
                // Editable fields
                VStack(spacing: 16) {
                    EditableField(label: "Name", text: $editedName, placeholder: "Enter name")
                    EditableField(label: "Age", text: $editedAge, placeholder: "Enter age", keyboardType: .numberPad)
                    EditableField(label: "Bio", text: $editedBio, placeholder: "Enter bio", isMultiline: true)
                    EditableField(label: "Job", text: $editedJob, placeholder: "Enter job")
                    EditableField(label: "School", text: $editedSchool, placeholder: "Enter school")
                    EditableField(label: "Location", text: $editedLocation, placeholder: "Enter location")
                }
                .padding(.horizontal, 24)
                
                // Prompts section
                if !profile.prompts.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Prompts")
                            .font(.headline)
                            .padding(.horizontal, 24)
                        
                        ForEach(profile.prompts) { prompt in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(prompt.prompt)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text(prompt.answer)
                                    .font(.subheadline)
                            }
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(.systemGray6))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .padding(.horizontal, 24)
                        }
                    }
                }
                
                // Interests
                if !profile.interests.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Interests")
                            .font(.headline)
                            .padding(.horizontal, 24)
                        
                        FlowLayout(spacing: 8) {
                            ForEach(profile.interests, id: \.self) { interest in
                                Text(interest)
                                    .font(.caption)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color.pink.opacity(0.1))
                                    .foregroundStyle(.pink)
                                    .clipShape(Capsule())
                            }
                        }
                        .padding(.horizontal, 24)
                    }
                }
                
                // Hooks
                if !profile.hooks.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "lightbulb.fill")
                                .foregroundStyle(.yellow)
                            Text("Conversation Hooks")
                                .font(.headline)
                        }
                        .padding(.horizontal, 24)
                        
                        ForEach(profile.hooks, id: \.self) { hook in
                            HStack {
                                Image(systemName: "sparkle")
                                    .foregroundStyle(.pink)
                                Text(hook)
                                    .font(.subheadline)
                            }
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.yellow.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .padding(.horizontal, 24)
                        }
                    }
                }
                
                // Action buttons
                VStack(spacing: 12) {
                    Button(action: saveAndContinue) {
                        HStack {
                            Image(systemName: "sparkles")
                            Text("Generate Messages")
                        }
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(
                                colors: [.pink, .purple],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    
                    Button(action: onCancel) {
                        Text("Start Over")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
        .onAppear {
            editedName = profile.name ?? ""
            editedAge = profile.age.map { String($0) } ?? ""
            editedBio = profile.bio ?? ""
            editedJob = profile.job ?? ""
            editedSchool = profile.school ?? ""
            editedLocation = profile.location ?? ""
        }
    }
    
    private func saveAndContinue() {
        profile.name = editedName.isEmpty ? nil : editedName
        profile.age = Int(editedAge)
        profile.bio = editedBio.isEmpty ? nil : editedBio
        profile.job = editedJob.isEmpty ? nil : editedJob
        profile.school = editedSchool.isEmpty ? nil : editedSchool
        profile.location = editedLocation.isEmpty ? nil : editedLocation
        profile.updatedAt = Date()
        
        onContinue()
    }
}

struct EditableField: View {
    let label: String
    @Binding var text: String
    var placeholder: String = ""
    var keyboardType: UIKeyboardType = .default
    var isMultiline: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            
            if isMultiline {
                TextField(placeholder, text: $text, axis: .vertical)
                    .lineLimit(3...6)
                    .textFieldStyle(.plain)
                    .padding()
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            } else {
                TextField(placeholder, text: $text)
                    .keyboardType(keyboardType)
                    .textFieldStyle(.plain)
                    .padding()
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }
}

struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(in: proposal.width ?? 0, subviews: subviews, spacing: spacing)
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(in: bounds.width, subviews: subviews, spacing: spacing)
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x,
                                       y: bounds.minY + result.positions[index].y),
                          proposal: .unspecified)
        }
    }
    
    struct FlowResult {
        var size: CGSize = .zero
        var positions: [CGPoint] = []
        
        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var x: CGFloat = 0
            var y: CGFloat = 0
            var rowHeight: CGFloat = 0
            
            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                
                if x + size.width > maxWidth && x > 0 {
                    x = 0
                    y += rowHeight + spacing
                    rowHeight = 0
                }
                
                positions.append(CGPoint(x: x, y: y))
                rowHeight = max(rowHeight, size.height)
                x += size.width + spacing
            }
            
            self.size = CGSize(width: maxWidth, height: y + rowHeight)
        }
    }
}

#Preview {
    NavigationStack {
        ProfilePreviewView(
            profile: .constant(MatchProfile(
                name: "Emma",
                age: 28,
                bio: "Dog mom, coffee enthusiast, hiking lover",
                prompts: [
                    PromptAnswer(prompt: "A perfect day would be", answer: "Morning hike, afternoon coffee shop, evening cooking dinner with friends"),
                    PromptAnswer(prompt: "My simple pleasures", answer: "Fresh coffee, good books, sunny days")
                ],
                interests: ["Hiking", "Coffee", "Dogs", "Travel", "Cooking"],
                job: "Product Designer",
                location: "San Francisco",
                hooks: ["Loves hiking - ask about favorite trails", "Has a dog - great conversation starter"]
            )),
            onContinue: {},
            onCancel: {}
        )
    }
}
