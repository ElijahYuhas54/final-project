import SwiftUI

struct ProfileSetupView: View {
    @EnvironmentObject var userViewModel: UserViewModel
    @Environment(\.dismiss) var dismiss
    
    @State private var weight = ""
    @State private var height = ""
    @State private var age = ""
    @State private var fitnessLevel = "Beginner"
    @State private var goals = ""
    @State private var showingError = false
    @State private var errorMessage = ""
    
    let fitnessLevels = ["Beginner", "Intermediate", "Advanced", "Professional"]
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Physical Information")) {
                    HStack {
                        Text("Weight (kg)")
                        Spacer()
                        TextField("70", text: $weight)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                    
                    HStack {
                        Text("Height (cm)")
                        Spacer()
                        TextField("170", text: $height)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                    
                    HStack {
                        Text("Age")
                        Spacer()
                        TextField("25", text: $age)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                    }
                }
                
                Section(header: Text("Fitness Information")) {
                    Picker("Fitness Level", selection: $fitnessLevel) {
                        ForEach(fitnessLevels, id: \.self) { level in
                            Text(level)
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Your Goals")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        TextEditor(text: $goals)
                            .frame(minHeight: 100)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                            )
                    }
                }
                
                Section {
                    Button(action: saveProfile) {
                        if userViewModel.isLoading {
                            HStack {
                                Spacer()
                                ProgressView()
                                Spacer()
                            }
                        } else {
                            Text("Save Profile")
                                .frame(maxWidth: .infinity)
                                .foregroundColor(.blue)
                        }
                    }
                    .disabled(userViewModel.isLoading)
                }
            }
            .navigationTitle("Set Up Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private func saveProfile() {
        guard let weightValue = Double(weight),
              let heightValue = Double(height),
              let ageValue = Int(age) else {
            errorMessage = "Please enter valid numbers for weight, height, and age"
            showingError = true
            return
        }
        
        guard weightValue > 0, heightValue > 0, ageValue > 0 else {
            errorMessage = "Please enter positive values"
            showingError = true
            return
        }
        
        guard !goals.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = "Please enter your fitness goals"
            showingError = true
            return
        }
        
        userViewModel.saveUserProfile(
            weight: weightValue,
            height: heightValue,
            age: ageValue,
            fitnessLevel: fitnessLevel,
            goals: goals
        )
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            if userViewModel.errorMessage.isEmpty {
                dismiss()
            } else {
                errorMessage = userViewModel.errorMessage
                showingError = true
            }
        }
    }
}
