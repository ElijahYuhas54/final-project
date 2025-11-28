import SwiftUI

struct WorkoutFeedbackView: View {
    let workoutPlan: WorkoutPlan
    @EnvironmentObject var userViewModel: UserViewModel
    @StateObject private var dataCollection = DataCollectionService()
    @Environment(\.dismiss) var dismiss
    
    @State private var completionRate: Double = 0.5
    @State private var difficultyRating: Int = 3
    @State private var effectivenessRating: Int = 3
    @State private var injuryOccurred = false
    @State private var daysCompleted = 0
    @State private var feedbackText = ""
    @State private var showingSuccess = false
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Workout Completion")) {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Completion Rate: \(Int(completionRate * 100))%")
                            .font(.subheadline)
                        
                        Slider(value: $completionRate, in: 0...1, step: 0.05)
                            .accentColor(.blue)
                    }
                    
                    Stepper("Days Completed: \(daysCompleted)", value: $daysCompleted, in: 0...365)
                }
                
                Section(header: Text("Difficulty Rating")) {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("How difficult was this workout?")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        HStack(spacing: 8) {
                            ForEach(1...5, id: \.self) { rating in
                                Image(systemName: rating <= difficultyRating ? "star.fill" : "star")
                                    .foregroundColor(rating <= difficultyRating ? .yellow : .gray)
                                    .font(.title2)
                                    .onTapGesture {
                                        difficultyRating = rating
                                        print("DEBUG: Difficulty rating set to: \(rating)")
                                    }
                            }
                        }
                        
                        Text(difficultyDescription)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                
                Section(header: Text("Effectiveness Rating")) {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("How effective was this workout?")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        HStack(spacing: 8) {
                            ForEach(1...5, id: \.self) { rating in
                                Image(systemName: rating <= effectivenessRating ? "star.fill" : "star")
                                    .foregroundColor(rating <= effectivenessRating ? .green : .gray)
                                    .font(.title2)
                                    .onTapGesture {
                                        effectivenessRating = rating
                                        print("DEBUG: Effectiveness rating set to: \(rating)")
                                    }
                            }
                        }
                        
                        Text(effectivenessDescription)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                
                Section(header: Text("Safety")) {
                    Toggle("Did any injury occur?", isOn: $injuryOccurred)
                        .toggleStyle(SwitchToggleStyle(tint: .red))
                    
                    if injuryOccurred {
                        Text("Please provide details in the feedback section")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
                
                Section(header: Text("Additional Feedback")) {
                    TextEditor(text: $feedbackText)
                        .frame(minHeight: 100)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                        )
                }
                
                Section {
                    Button(action: submitFeedback) {
                        if dataCollection.isLoading {
                            HStack {
                                Spacer()
                                ProgressView()
                                Spacer()
                            }
                        } else {
                            Text("Submit Feedback")
                                .frame(maxWidth: .infinity)
                                .foregroundColor(.blue)
                        }
                    }
                    .disabled(dataCollection.isLoading)
                }
            }
            .navigationTitle("Workout Feedback")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        print("DEBUG: Cancel tapped, dismissing feedback view")
                        dismiss()
                    }
                }
            }
            .alert("Success", isPresented: $showingSuccess) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text("Thank you for your feedback! This helps improve our AI recommendations.")
            }
            .onAppear {
                print("DEBUG: WorkoutFeedbackView appeared")
                print("DEBUG: Plan ID: \(workoutPlan.id ?? "no ID")")
            }
        }
    }
    
    private var difficultyDescription: String {
        switch difficultyRating {
        case 1: return "Very Easy"
        case 2: return "Easy"
        case 3: return "Moderate"
        case 4: return "Hard"
        case 5: return "Very Hard"
        default: return ""
        }
    }
    
    private var effectivenessDescription: String {
        switch effectivenessRating {
        case 1: return "Not Effective"
        case 2: return "Slightly Effective"
        case 3: return "Moderately Effective"
        case 4: return "Very Effective"
        case 5: return "Extremely Effective"
        default: return ""
        }
    }
    
    private func submitFeedback() {
        guard let profile = userViewModel.userProfile,
              let planId = workoutPlan.id else {
            print("DEBUG: Missing profile or plan ID")
            return
        }
        
        print("DEBUG: Submitting feedback for plan: \(planId)")
        
        dataCollection.submitWorkoutFeedback(
            workoutPlanId: planId,
            completionRate: completionRate,
            difficultyRating: difficultyRating,
            effectivenessRating: effectivenessRating,
            injuryOccurred: injuryOccurred,
            daysCompleted: daysCompleted,
            feedbackText: feedbackText,
            userProfile: profile
        )
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            if dataCollection.errorMessage.isEmpty {
                showingSuccess = true
            } else {
                print("DEBUG: Feedback error: \(dataCollection.errorMessage)")
            }
        }
    }
}
