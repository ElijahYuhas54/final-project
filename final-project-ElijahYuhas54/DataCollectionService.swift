import Foundation
import FirebaseFirestore
import FirebaseAuth

struct WorkoutFeedback: Codable, Identifiable {
    @DocumentID var id: String?
    var userId: String
    var workoutPlanId: String
    var completionRate: Double
    var difficultyRating: Int
    var effectivenessRating: Int
    var injuryOccurred: Bool
    var daysCompleted: Int
    var feedbackText: String
    var userAge: Int
    var userWeight: Double
    var userHeight: Double
    var fitnessLevel: String
    var workoutDuration: String
    var createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId
        case workoutPlanId
        case completionRate
        case difficultyRating
        case effectivenessRating
        case injuryOccurred
        case daysCompleted
        case feedbackText
        case userAge
        case userWeight
        case userHeight
        case fitnessLevel
        case workoutDuration
        case createdAt
    }
    
    init(id: String? = nil, userId: String, workoutPlanId: String, completionRate: Double, difficultyRating: Int, effectivenessRating: Int, injuryOccurred: Bool, daysCompleted: Int, feedbackText: String, userAge: Int, userWeight: Double, userHeight: Double, fitnessLevel: String, workoutDuration: String, createdAt: Date) {
        self._id = DocumentID(wrappedValue: id)
        self.userId = userId
        self.workoutPlanId = workoutPlanId
        self.completionRate = completionRate
        self.difficultyRating = difficultyRating
        self.effectivenessRating = effectivenessRating
        self.injuryOccurred = injuryOccurred
        self.daysCompleted = daysCompleted
        self.feedbackText = feedbackText
        self.userAge = userAge
        self.userWeight = userWeight
        self.userHeight = userHeight
        self.fitnessLevel = fitnessLevel
        self.workoutDuration = workoutDuration
        self.createdAt = createdAt
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        _id = try container.decodeIfPresent(DocumentID<String>.self, forKey: .id) ?? DocumentID(wrappedValue: nil)
        userId = try container.decodeIfPresent(String.self, forKey: .userId) ?? ""
        workoutPlanId = try container.decodeIfPresent(String.self, forKey: .workoutPlanId) ?? ""
        completionRate = try container.decodeIfPresent(Double.self, forKey: .completionRate) ?? 0.0
        difficultyRating = try container.decodeIfPresent(Int.self, forKey: .difficultyRating) ?? 3
        effectivenessRating = try container.decodeIfPresent(Int.self, forKey: .effectivenessRating) ?? 3
        injuryOccurred = try container.decodeIfPresent(Bool.self, forKey: .injuryOccurred) ?? false
        daysCompleted = try container.decodeIfPresent(Int.self, forKey: .daysCompleted) ?? 0
        feedbackText = try container.decodeIfPresent(String.self, forKey: .feedbackText) ?? ""
        userAge = try container.decodeIfPresent(Int.self, forKey: .userAge) ?? 25
        userWeight = try container.decodeIfPresent(Double.self, forKey: .userWeight) ?? 70.0
        userHeight = try container.decodeIfPresent(Double.self, forKey: .userHeight) ?? 170.0
        fitnessLevel = try container.decodeIfPresent(String.self, forKey: .fitnessLevel) ?? "Intermediate"
        workoutDuration = try container.decodeIfPresent(String.self, forKey: .workoutDuration) ?? "Week"
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date()
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(userId, forKey: .userId)
        try container.encode(workoutPlanId, forKey: .workoutPlanId)
        try container.encode(completionRate, forKey: .completionRate)
        try container.encode(difficultyRating, forKey: .difficultyRating)
        try container.encode(effectivenessRating, forKey: .effectivenessRating)
        try container.encode(injuryOccurred, forKey: .injuryOccurred)
        try container.encode(daysCompleted, forKey: .daysCompleted)
        try container.encode(feedbackText, forKey: .feedbackText)
        try container.encode(userAge, forKey: .userAge)
        try container.encode(userWeight, forKey: .userWeight)
        try container.encode(userHeight, forKey: .userHeight)
        try container.encode(fitnessLevel, forKey: .fitnessLevel)
        try container.encode(workoutDuration, forKey: .workoutDuration)
        try container.encode(createdAt, forKey: .createdAt)
    }
}

struct WorkoutProgress: Codable, Identifiable {
    @DocumentID var id: String?
    var userId: String
    var workoutPlanId: String
    var date: Date
    var exercisesCompleted: [String]
    var duration: Int
    var caloriesBurned: Double
    var heartRateAvg: Double?
    var perceivedExertion: Int
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId
        case workoutPlanId
        case date
        case exercisesCompleted
        case duration
        case caloriesBurned
        case heartRateAvg
        case perceivedExertion
    }
}

class DataCollectionService: ObservableObject {
    @Published var feedbackList: [WorkoutFeedback] = []
    @Published var progressList: [WorkoutProgress] = []
    @Published var isLoading = false
    @Published var errorMessage = ""
    
    private let db = Firestore.firestore()
    
    func submitWorkoutFeedback(
        workoutPlanId: String,
        completionRate: Double,
        difficultyRating: Int,
        effectivenessRating: Int,
        injuryOccurred: Bool,
        daysCompleted: Int,
        feedbackText: String,
        userProfile: UserProfile
    ) {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        isLoading = true
        
        let feedback = WorkoutFeedback(
            userId: userId,
            workoutPlanId: workoutPlanId,
            completionRate: completionRate,
            difficultyRating: difficultyRating,
            effectivenessRating: effectivenessRating,
            injuryOccurred: injuryOccurred,
            daysCompleted: daysCompleted,
            feedbackText: feedbackText,
            userAge: userProfile.age,
            userWeight: userProfile.weight,
            userHeight: userProfile.height,
            fitnessLevel: userProfile.fitnessLevel,
            workoutDuration: "",
            createdAt: Date()
        )
        
        do {
            try db.collection("workoutFeedback").addDocument(from: feedback) { [weak self] error in
                DispatchQueue.main.async {
                    self?.isLoading = false
                    if let error = error {
                        self?.errorMessage = error.localizedDescription
                    }
                }
            }
        } catch {
            DispatchQueue.main.async {
                self.isLoading = false
                self.errorMessage = error.localizedDescription
            }
        }
    }
    
    func logWorkoutProgress(
        workoutPlanId: String,
        exercisesCompleted: [String],
        duration: Int,
        caloriesBurned: Double,
        heartRateAvg: Double?,
        perceivedExertion: Int
    ) {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        let progress = WorkoutProgress(
            userId: userId,
            workoutPlanId: workoutPlanId,
            date: Date(),
            exercisesCompleted: exercisesCompleted,
            duration: duration,
            caloriesBurned: caloriesBurned,
            heartRateAvg: heartRateAvg,
            perceivedExertion: perceivedExertion
        )
        
        do {
            try db.collection("workoutProgress").addDocument(from: progress)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func fetchAllFeedback() {
        print("DEBUG: Fetching all feedback from Firestore...")
        isLoading = true
        
        db.collection("workoutFeedback")
            .getDocuments { [weak self] snapshot, error in
                DispatchQueue.main.async {
                    self?.isLoading = false
                    if let error = error {
                        print("DEBUG: Error fetching feedback: \(error.localizedDescription)")
                        self?.errorMessage = error.localizedDescription
                        return
                    }
                    
                    print("DEBUG: Document count in snapshot: \(snapshot?.documents.count ?? 0)")
                    
                    var successCount = 0
                    var failCount = 0
                    
                    let feedback = snapshot?.documents.compactMap { doc -> WorkoutFeedback? in
                        do {
                            let decoded = try doc.data(as: WorkoutFeedback.self)
                            successCount += 1
                            return decoded
                        } catch {
                            failCount += 1
                            if failCount <= 3 {
                                print("DEBUG: Failed to decode document \(doc.documentID): \(error)")
                                print("DEBUG: Document data: \(doc.data())")
                            }
                            return nil
                        }
                    } ?? []
                    
                    print("DEBUG: Successfully decoded \(successCount) feedback entries")
                    print("DEBUG: Failed to decode \(failCount) entries")
                    
                    self?.feedbackList = feedback
                }
            }
    }
    
    func exportDatasetToCSV() -> String {
        var csv = "userId,age,weight,height,fitnessLevel,workoutDuration,completionRate,difficultyRating,effectivenessRating,injuryOccurred,daysCompleted\n"
        
        for feedback in feedbackList {
            csv += "\(feedback.userId),"
            csv += "\(feedback.userAge),"
            csv += "\(feedback.userWeight),"
            csv += "\(feedback.userHeight),"
            csv += "\(feedback.fitnessLevel),"
            csv += "\(feedback.workoutDuration),"
            csv += "\(feedback.completionRate),"
            csv += "\(feedback.difficultyRating),"
            csv += "\(feedback.effectivenessRating),"
            csv += "\(feedback.injuryOccurred ? 1 : 0),"
            csv += "\(feedback.daysCompleted)\n"
        }
        
        return csv
    }
}
