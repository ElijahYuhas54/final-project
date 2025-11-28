import Foundation
import FirebaseFirestore
import FirebaseAuth

struct TrainingData: Codable {
    var age: Int
    var weight: Double
    var height: Double
    var fitnessLevel: String
    var workoutDuration: String
    var completionRate: Double
    var difficultyRating: Int
    var effectivenessRating: Int
    var injuryOccurred: Bool
}

struct ModelPrediction: Codable {
    var recommendedDuration: String
    var expectedCompletionRate: Double
    var estimatedDifficulty: Int
    var safetyScore: Double
    var confidence: Double
}

struct ModelEvaluation: Codable {
    var accuracy: Double
    var precision: Double
    var recall: Double
    var f1Score: Double
    var confusionMatrix: [[Int]]
    var totalSamples: Int
}

class WorkoutRecommendationModel: ObservableObject {
    @Published var isTraining = false
    @Published var evaluationResults: ModelEvaluation?
    @Published var errorMessage = ""
    @Published var trainingProgress = ""
    
    private let db = Firestore.firestore()
    private let geminiAPIKey = "AIzaSyA-t4eI4eIghVxA9PaCziqQnaiVAn5-CiQ"
    
    init() {
    }
    
    func trainModel(trainingData: [TrainingData]) async {
        await MainActor.run {
            isTraining = true
            trainingProgress = "Preparing training data..."
        }
        
        let datasetSummary = prepareDatasetSummary(trainingData)
        
        let trainingPrompt = """
        You are a fitness AI model being trained on workout effectiveness data. Analyze this dataset and learn patterns:
        
        Dataset Summary:
        \(datasetSummary)
        
        Full Training Data (first 100 samples):
        \(formatTrainingData(Array(trainingData.prefix(100))))
        
        Learn these patterns:
        1. Which user profiles (age, weight, height, fitness level) successfully complete which workout durations?
        2. What difficulty ratings correlate with high completion rates?
        3. Which combinations lead to injuries (safety concerns)?
        4. What effectiveness ratings indicate optimal workout assignment?
        
        Respond with: "Model trained successfully. Key patterns identified: [list 5 key insights]"
        """
        
        do {
            await MainActor.run {
                trainingProgress = "Training model with Gemini AI..."
            }
            
            let text = try await callGeminiAPI(prompt: trainingPrompt)
            
            try await saveModelTrainingLog(
                trainingData: trainingData,
                trainingResponse: text
            )
            
            await MainActor.run {
                self.trainingProgress = "Training completed: \(text)"
                self.isTraining = false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "Training error: \(error.localizedDescription)"
                self.isTraining = false
            }
        }
    }
    
    func testModel(testData: [TrainingData]) async {
        await MainActor.run {
            isTraining = true
            trainingProgress = "Testing model..."
        }
        
        var predictions: [(actual: Bool, predicted: Bool)] = []
        
        for data in testData.prefix(50) {
            let prediction = await makePrediction(userData: data)
            let actualSuccess = data.completionRate >= 0.7 && !data.injuryOccurred
            let predictedSuccess = prediction.expectedCompletionRate >= 0.7 && prediction.safetyScore >= 0.8
            
            predictions.append((actual: actualSuccess, predicted: predictedSuccess))
        }
        
        let evaluation = calculateMetrics(predictions: predictions)
        
        await MainActor.run {
            self.evaluationResults = evaluation
            self.isTraining = false
            self.trainingProgress = "Testing completed"
        }
    }
    
    func makePrediction(userData: TrainingData) async -> ModelPrediction {
        let predictionPrompt = """
        Based on learned patterns, predict workout outcomes for this user:
        
        User Profile:
        - Age: \(userData.age)
        - Weight: \(userData.weight) kg
        - Height: \(userData.height) cm
        - Fitness Level: \(userData.fitnessLevel)
        - Requested Duration: \(userData.workoutDuration)
        
        Predict and return ONLY a JSON object with these exact fields:
        {
          "recommendedDuration": "Week",
          "expectedCompletionRate": 0.85,
          "estimatedDifficulty": 3,
          "safetyScore": 0.92,
          "confidence": 0.88
        }
        
        Use these guidelines:
        - expectedCompletionRate: 0.0 to 1.0 (likelihood of completing the workout)
        - estimatedDifficulty: 1-5 scale (1=very easy, 5=very hard)
        - safetyScore: 0.0 to 1.0 (higher = safer, lower risk of injury)
        - confidence: 0.0 to 1.0 (model confidence in prediction)
        
        Return ONLY the JSON object, no other text.
        """
        
        do {
            let text = try await callGeminiAPI(prompt: predictionPrompt)
            
            let cleanedText = text
                .replacingOccurrences(of: "```json", with: "")
                .replacingOccurrences(of: "```", with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
            
            let decoder = JSONDecoder()
            if let prediction = try? decoder.decode(ModelPrediction.self, from: cleanedText.data(using: .utf8)!) {
                return prediction
            }
        } catch {
            print("Prediction error: \(error)")
        }
        
        return ModelPrediction(
            recommendedDuration: userData.workoutDuration,
            expectedCompletionRate: 0.5,
            estimatedDifficulty: 3,
            safetyScore: 0.5,
            confidence: 0.3
        )
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
    
    private func prepareDatasetSummary(_ data: [TrainingData]) -> String {
        let totalSamples = data.count
        let avgCompletionRate = data.map { $0.completionRate }.reduce(0, +) / Double(data.count)
        let injuryRate = Double(data.filter { $0.injuryOccurred }.count) / Double(totalSamples)
        
        let fitnessLevelCounts = Dictionary(grouping: data, by: { $0.fitnessLevel })
            .mapValues { $0.count }
        
        return """
        Total Samples: \(totalSamples)
        Average Completion Rate: \(String(format: "%.2f", avgCompletionRate))
        Injury Rate: \(String(format: "%.2f%%", injuryRate * 100))
        Fitness Level Distribution: \(fitnessLevelCounts)
        """
    }
    
    private func formatTrainingData(_ data: [TrainingData]) -> String {
        return data.map { sample in
            "Age: \(sample.age), Weight: \(sample.weight)kg, Height: \(sample.height)cm, " +
            "Level: \(sample.fitnessLevel), Duration: \(sample.workoutDuration), " +
            "Completion: \(String(format: "%.0f%%", sample.completionRate * 100)), " +
            "Difficulty: \(sample.difficultyRating)/5, Effectiveness: \(sample.effectivenessRating)/5, " +
            "Injury: \(sample.injuryOccurred ? "Yes" : "No")"
        }.joined(separator: "\n")
    }
    
    private func calculateMetrics(predictions: [(actual: Bool, predicted: Bool)]) -> ModelEvaluation {
        var truePositives = 0
        var trueNegatives = 0
        var falsePositives = 0
        var falseNegatives = 0
        
        for prediction in predictions {
            switch (prediction.actual, prediction.predicted) {
            case (true, true): truePositives += 1
            case (false, false): trueNegatives += 1
            case (false, true): falsePositives += 1
            case (true, false): falseNegatives += 1
            }
        }
        
        let accuracy = Double(truePositives + trueNegatives) / Double(predictions.count)
        let precision = truePositives > 0 ? Double(truePositives) / Double(truePositives + falsePositives) : 0
        let recall = truePositives > 0 ? Double(truePositives) / Double(truePositives + falseNegatives) : 0
        let f1Score = (precision + recall) > 0 ? 2 * (precision * recall) / (precision + recall) : 0
        
        let confusionMatrix = [
            [truePositives, falsePositives],
            [falseNegatives, trueNegatives]
        ]
        
        return ModelEvaluation(
            accuracy: accuracy,
            precision: precision,
            recall: recall,
            f1Score: f1Score,
            confusionMatrix: confusionMatrix,
            totalSamples: predictions.count
        )
    }
    
    private func saveModelTrainingLog(trainingData: [TrainingData], trainingResponse: String) async throws {
        let log: [String: Any] = [
            "timestamp": Date(),
            "sampleCount": trainingData.count,
            "trainingResponse": trainingResponse,
            "modelVersion": "gemini-1.5-flash"
        ]
        
        try await db.collection("modelTrainingLogs").addDocument(data: log)
    }
}
