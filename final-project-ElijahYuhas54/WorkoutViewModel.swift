import Foundation
import FirebaseFirestore
import FirebaseAuth

class WorkoutViewModel: ObservableObject {
    @Published var workoutPlans: [WorkoutPlan] = []
    @Published var isLoading = false
    @Published var errorMessage = ""
    @Published var generatedPlan: String = ""
    
    private let db = Firestore.firestore()
    private let geminiAPIKey = "AIzaSyA-t4eI4eIghVxA9PaCziqQnaiVAn5-CiQ"
    
    init() {
    }
    
    func fetchWorkoutPlans() {
        guard let userId = Auth.auth().currentUser?.uid else {
            print("DEBUG: No user ID found")
            DispatchQueue.main.async {
                self.isLoading = false
            }
            return
        }
        
        print("DEBUG: Fetching plans for user: \(userId)")
        isLoading = true
        
        db.collection("workoutPlans")
            .whereField("userId", isEqualTo: userId)
            .getDocuments { [weak self] snapshot, error in
                DispatchQueue.main.async {
                    self?.isLoading = false
                    if let error = error {
                        print("DEBUG: Error fetching plans: \(error.localizedDescription)")
                        self?.errorMessage = error.localizedDescription
                        return
                    }
                    
                    let plans = snapshot?.documents.compactMap { doc in
                        try? doc.data(as: WorkoutPlan.self)
                    }.sorted(by: { $0.createdAt > $1.createdAt }) ?? []
                    
                    print("DEBUG: Fetched \(plans.count) plans")
                    self?.workoutPlans = plans
                }
            }
    }
    
    func generateWorkoutPlan(userProfile: UserProfile, duration: WorkoutDuration) async {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        await MainActor.run {
            isLoading = true
            errorMessage = ""
            generatedPlan = ""
        }
        
        let prompt = """
        Create a detailed workout plan with the following specifications:
        
        User Information:
        - Age: \(userProfile.age) years
        - Weight: \(userProfile.weight) kg
        - Height: \(userProfile.height) cm
        - Fitness Level: \(userProfile.fitnessLevel)
        - Goals: \(userProfile.goals)
        
        Duration: \(duration.rawValue)
        
        Please provide a comprehensive workout plan that includes:
        1. Specific exercises with sets, reps, and rest periods
        2. Progression guidelines
        3. Warm-up and cool-down routines
        4. Safety considerations based on the user's profile
        5. Nutrition tips if applicable
        
        Format the plan clearly with day-by-day breakdown if applicable.
        """
        
        var text = ""
        
        do {
            // Check if API key is set
            if geminiAPIKey == "YOUR_GEMINI_API_KEY_HERE" || geminiAPIKey.isEmpty {
                print("DEBUG: Using mock data")
                // Use mock data for testing
                text = generateMockWorkoutPlan(userProfile: userProfile, duration: duration)
            } else {
                print("DEBUG: Calling Gemini API")
                text = try await callGeminiAPI(prompt: prompt)
                print("DEBUG: Gemini API response received: \(text.prefix(100))...")
            }
            
            await MainActor.run {
                self.generatedPlan = text
            }
            
            let workoutPlan = WorkoutPlan(
                userId: userId,
                duration: duration.rawValue,
                plan: text,
                createdAt: Date(),
                userWeight: userProfile.weight,
                userHeight: userProfile.height,
                userAge: userProfile.age
            )
            
            print("DEBUG: Saving workout plan to Firestore")
            let docRef = try db.collection("workoutPlans").addDocument(from: workoutPlan)
            
            // Fetch the saved document with its ID
            docRef.getDocument { [weak self] snapshot, error in
                DispatchQueue.main.async {
                    self?.isLoading = false
                    if let error = error {
                        print("DEBUG: Error fetching saved document: \(error.localizedDescription)")
                        self?.errorMessage = error.localizedDescription
                    } else if let snapshot = snapshot, snapshot.exists {
                        if let savedPlan = try? snapshot.data(as: WorkoutPlan.self) {
                            print("DEBUG: Plan saved successfully with ID: \(savedPlan.id ?? "unknown")")
                            print("DEBUG: Plan duration: \(savedPlan.duration)")
                            self?.workoutPlans.insert(savedPlan, at: 0)
                        }
                    }
                }
            }
        } catch {
            print("DEBUG: Error in generateWorkoutPlan: \(error.localizedDescription)")
            await MainActor.run {
                self.isLoading = false
                self.errorMessage = "Error generating workout plan: \(error.localizedDescription)"
            }
        }
    }
    
    private func generateMockWorkoutPlan(userProfile: UserProfile, duration: WorkoutDuration) -> String {
        return """
        PERSONALIZED \(duration.rawValue.uppercased()) WORKOUT PLAN
        
        Profile: \(userProfile.age) years old | \(Int(userProfile.weight))kg | \(Int(userProfile.height))cm | \(userProfile.fitnessLevel)
        Goals: \(userProfile.goals)
        
        WARM-UP (10 minutes)
        • Dynamic stretching - 5 minutes
        • Light cardio (jumping jacks, high knees) - 5 minutes
        
        MAIN WORKOUT
        
        Day 1: Upper Body Strength
        • Push-ups: 3 sets x 10-12 reps
        • Dumbbell rows: 3 sets x 12 reps
        • Shoulder press: 3 sets x 10 reps
        • Bicep curls: 3 sets x 12 reps
        • Tricep dips: 3 sets x 10 reps
        Rest: 60-90 seconds between sets
        
        Day 2: Lower Body & Core
        • Squats: 4 sets x 12 reps
        • Lunges: 3 sets x 10 reps per leg
        • Leg raises: 3 sets x 15 reps
        • Plank: 3 sets x 45-60 seconds
        • Russian twists: 3 sets x 20 reps
        Rest: 60 seconds between sets
        
        Day 3: Active Recovery
        • Light walking or yoga - 30 minutes
        • Gentle stretching - 15 minutes
        
        Day 4: Full Body Circuit
        • Burpees: 3 sets x 8 reps
        • Mountain climbers: 3 sets x 20 reps
        • Jump squats: 3 sets x 10 reps
        • Push-ups: 3 sets x 12 reps
        • Plank: 3 sets x 60 seconds
        Rest: 45 seconds between exercises
        
        COOL-DOWN (10 minutes)
        • Static stretching focusing on worked muscles
        • Deep breathing exercises
        
        PROGRESSION GUIDELINES
        • Increase weights by 5% when you can complete all sets comfortably
        • Add 1-2 reps per set each week
        • Reduce rest time by 5-10 seconds as fitness improves
        
        NUTRITION TIPS
        • Protein: 1.6-2.2g per kg body weight daily
        • Stay hydrated: 2-3 liters of water per day
        • Eat within 30 minutes post-workout for optimal recovery
        • Focus on whole foods: lean proteins, complex carbs, healthy fats
        
        SAFETY NOTES
        • Start with lighter weights to perfect form
        • Stop immediately if you feel sharp pain
        • Rest 48 hours between working the same muscle groups
        • Listen to your body and take extra rest days if needed
        
        Note: This is a mock workout plan for testing. Replace API key for AI-generated plans.
        """
    }
    
    private func callGeminiAPI(prompt: String) async throws -> String {
        let url = URL(string: "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=\(geminiAPIKey)")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let requestBody: [String: Any] = [
            "contents": [
                [
                    "parts": [
                        ["text": prompt]
                    ]
                ]
            ]
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "Invalid response", code: -1)
        }
        
        guard httpResponse.statusCode == 200 else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw NSError(domain: "API Error: \(errorMessage)", code: httpResponse.statusCode)
        }
        
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        
        if let candidates = json?["candidates"] as? [[String: Any]],
           let firstCandidate = candidates.first,
           let content = firstCandidate["content"] as? [String: Any],
           let parts = content["parts"] as? [[String: Any]],
           let firstPart = parts.first,
           let text = firstPart["text"] as? String {
            return text
        }
        
        throw NSError(domain: "Failed to parse response", code: -1)
    }
    
    func deleteWorkoutPlan(_ plan: WorkoutPlan) {
        guard let planId = plan.id else { return }
        
        db.collection("workoutPlans").document(planId).delete { [weak self] error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.errorMessage = error.localizedDescription
                } else {
                    self?.fetchWorkoutPlans()
                }
            }
        }
    }
}
