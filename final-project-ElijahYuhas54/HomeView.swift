import SwiftUI

struct HomeView: View {
    @EnvironmentObject var userViewModel: UserViewModel
    @EnvironmentObject var workoutViewModel: WorkoutViewModel
    @State private var selectedDuration: WorkoutDuration = .week
    @State private var showingProfileSetup = false
    @State private var showingGeneratedPlan = false
    
    var body: some View {
        NavigationView {
            ZStack {
                ScrollView {
                    VStack(spacing: 25) {
                        if userViewModel.userProfile == nil {
                            profileSetupPrompt
                        } else {
                            welcomeSection
                            durationSelector
                            generateButton
                            
                            if !workoutViewModel.generatedPlan.isEmpty {
                                latestPlanPreview
                            }
                        }
                    }
                    .padding()
                }
                
                if workoutViewModel.isLoading {
                    LoadingView(message: "Generating your personalized workout plan...")
                }
            }
            .navigationTitle("Workout AI")
            .sheet(isPresented: $showingProfileSetup) {
                ProfileSetupView()
                    .environmentObject(userViewModel)
            }
            .sheet(isPresented: $showingGeneratedPlan) {
                GeneratedPlanView(plan: workoutViewModel.generatedPlan)
            }
        }
    }
    
    private var profileSetupPrompt: some View {
        VStack(spacing: 20) {
            Image(systemName: "person.crop.circle.badge.plus")
                .font(.system(size: 80))
                .foregroundColor(.blue)
            
            Text("Complete Your Profile")
                .font(.title)
                .fontWeight(.bold)
            
            Text("To generate personalized workout plans, please set up your profile first.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal)
            
            Button(action: { showingProfileSetup = true }) {
                Text("Set Up Profile")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color.blue)
                    .cornerRadius(10)
            }
            .padding(.horizontal)
        }
        .padding(.top, 50)
    }
    
    private var welcomeSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Generate New Plan")
                .font(.title2)
                .fontWeight(.bold)
            
            if let profile = userViewModel.userProfile {
                HStack {
                    InfoCard(title: "Age", value: "\(profile.age)")
                    InfoCard(title: "Weight", value: "\(Int(profile.weight)) kg")
                    InfoCard(title: "Height", value: "\(Int(profile.height)) cm")
                }
            }
        }
    }
    
    private var durationSelector: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Select Duration")
                .font(.headline)
            
            Picker("Duration", selection: $selectedDuration) {
                ForEach(WorkoutDuration.allCases, id: \.self) { duration in
                    Text(duration.rawValue).tag(duration)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
        }
    }
    
    private var generateButton: some View {
        Button(action: generatePlan) {
            HStack {
                Image(systemName: "sparkles")
                Text("Generate Workout Plan")
                    .fontWeight(.semibold)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 55)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [Color.blue, Color.purple]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(10)
        }
        .disabled(workoutViewModel.isLoading)
    }
    
    private var latestPlanPreview: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Latest Generated Plan")
                    .font(.headline)
                
                Spacer()
                
                Button(action: { showingGeneratedPlan = true }) {
                    Text("View Full")
                        .font(.subheadline)
                        .foregroundColor(.blue)
                }
            }
            
            Text(workoutViewModel.generatedPlan)
                .lineLimit(5)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
        }
    }
    
    private func generatePlan() {
        guard let profile = userViewModel.userProfile else { return }
        
        Task {
            await workoutViewModel.generateWorkoutPlan(userProfile: profile, duration: selectedDuration)
            
            // Wait a moment for the plan to be saved and show the sheet
            await MainActor.run {
                if !workoutViewModel.generatedPlan.isEmpty {
                    showingGeneratedPlan = true
                }
            }
        }
    }
}

struct InfoCard: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(value)
                .font(.headline)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.blue.opacity(0.1))
        .cornerRadius(10)
    }
}

struct LoadingView: View {
    let message: String
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                ProgressView()
                    .scaleEffect(1.5)
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                
                Text(message)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            .padding(30)
            .background(Color.gray.opacity(0.9))
            .cornerRadius(20)
        }
    }
}

#Preview {
    HomeView()
        .environmentObject(UserViewModel())
        .environmentObject(WorkoutViewModel())
}
