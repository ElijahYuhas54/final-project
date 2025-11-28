import Foundation

class DataPreprocessor {
    
    func cleanAndNormalize(feedbackList: [WorkoutFeedback]) -> [TrainingData] {
        return feedbackList.compactMap { feedback -> TrainingData? in
            guard isValidFeedback(feedback) else { return nil }
            
            return TrainingData(
                age: feedback.userAge,
                weight: normalizeWeight(feedback.userWeight),
                height: normalizeHeight(feedback.userHeight),
                fitnessLevel: normalizeFitnessLevel(feedback.fitnessLevel),
                workoutDuration: feedback.workoutDuration,
                completionRate: feedback.completionRate,
                difficultyRating: feedback.difficultyRating,
                effectivenessRating: feedback.effectivenessRating,
                injuryOccurred: feedback.injuryOccurred
            )
        }
    }
    
    func splitTrainTest(data: [TrainingData], testRatio: Double = 0.2) -> (train: [TrainingData], test: [TrainingData]) {
        let shuffled = data.shuffled()
        let testSize = Int(Double(data.count) * testRatio)
        let trainSize = data.count - testSize
        
        let trainData = Array(shuffled.prefix(trainSize))
        let testData = Array(shuffled.suffix(testSize))
        
        return (train: trainData, test: testData)
    }
    
    func encodeCategories(data: [TrainingData]) -> [EncodedTrainingData] {
        return data.map { sample in
            EncodedTrainingData(
                age: sample.age,
                weight: sample.weight,
                height: sample.height,
                fitnessLevelEncoded: encodeFitnessLevel(sample.fitnessLevel),
                durationEncoded: encodeDuration(sample.workoutDuration),
                completionRate: sample.completionRate,
                difficultyRating: sample.difficultyRating,
                effectivenessRating: sample.effectivenessRating,
                injuryOccurred: sample.injuryOccurred ? 1 : 0
            )
        }
    }
    
    func balanceDataset(data: [TrainingData]) -> [TrainingData] {
        let successful = data.filter { $0.completionRate >= 0.7 && !$0.injuryOccurred }
        let unsuccessful = data.filter { $0.completionRate < 0.7 || $0.injuryOccurred }
        
        let minCount = min(successful.count, unsuccessful.count)
        
        let balancedSuccessful = Array(successful.shuffled().prefix(minCount))
        let balancedUnsuccessful = Array(unsuccessful.shuffled().prefix(minCount))
        
        return (balancedSuccessful + balancedUnsuccessful).shuffled()
    }
    
    func removeOutliers(data: [TrainingData]) -> [TrainingData] {
        return data.filter { sample in
            sample.age >= 13 && sample.age <= 80 &&
            sample.weight >= 30 && sample.weight <= 200 &&
            sample.height >= 120 && sample.height <= 230 &&
            sample.completionRate >= 0 && sample.completionRate <= 1 &&
            sample.difficultyRating >= 1 && sample.difficultyRating <= 5 &&
            sample.effectivenessRating >= 1 && sample.effectivenessRating <= 5
        }
    }
    
    func generateStatistics(data: [TrainingData]) -> DatasetStatistics {
        let ages = data.map { Double($0.age) }
        let weights = data.map { $0.weight }
        let heights = data.map { $0.height }
        let completionRates = data.map { $0.completionRate }
        
        return DatasetStatistics(
            totalSamples: data.count,
            ageStats: calculateStats(ages),
            weightStats: calculateStats(weights),
            heightStats: calculateStats(heights),
            completionRateStats: calculateStats(completionRates),
            injuryCount: data.filter { $0.injuryOccurred }.count,
            fitnessLevelDistribution: Dictionary(grouping: data, by: { $0.fitnessLevel }).mapValues { $0.count },
            durationDistribution: Dictionary(grouping: data, by: { $0.workoutDuration }).mapValues { $0.count }
        )
    }
    
    private func isValidFeedback(_ feedback: WorkoutFeedback) -> Bool {
        return feedback.userAge > 0 &&
               feedback.userWeight > 0 &&
               feedback.userHeight > 0 &&
               !feedback.fitnessLevel.isEmpty &&
               !feedback.workoutDuration.isEmpty &&
               feedback.completionRate >= 0 && feedback.completionRate <= 1 &&
               feedback.difficultyRating >= 1 && feedback.difficultyRating <= 5 &&
               feedback.effectivenessRating >= 1 && feedback.effectivenessRating <= 5
    }
    
    private func normalizeWeight(_ weight: Double) -> Double {
        return min(max(weight, 30), 200)
    }
    
    private func normalizeHeight(_ height: Double) -> Double {
        return min(max(height, 120), 230)
    }
    
    private func normalizeFitnessLevel(_ level: String) -> String {
        let normalized = level.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        switch normalized {
        case "beginner", "novice": return "Beginner"
        case "intermediate", "medium": return "Intermediate"
        case "advanced": return "Advanced"
        case "professional", "expert": return "Professional"
        default: return "Intermediate"
        }
    }
    
    private func encodeFitnessLevel(_ level: String) -> Int {
        switch level {
        case "Beginner": return 1
        case "Intermediate": return 2
        case "Advanced": return 3
        case "Professional": return 4
        default: return 2
        }
    }
    
    private func encodeDuration(_ duration: String) -> Int {
        switch duration {
        case "Day": return 1
        case "Week": return 7
        case "Month": return 30
        case "Year": return 365
        default: return 7
        }
    }
    
    private func calculateStats(_ values: [Double]) -> Statistics {
        let sorted = values.sorted()
        let mean = values.reduce(0, +) / Double(values.count)
        let variance = values.map { pow($0 - mean, 2) }.reduce(0, +) / Double(values.count)
        let stdDev = sqrt(variance)
        
        return Statistics(
            mean: mean,
            median: sorted[sorted.count / 2],
            min: sorted.first ?? 0,
            max: sorted.last ?? 0,
            stdDev: stdDev
        )
    }
}

struct EncodedTrainingData {
    var age: Int
    var weight: Double
    var height: Double
    var fitnessLevelEncoded: Int
    var durationEncoded: Int
    var completionRate: Double
    var difficultyRating: Int
    var effectivenessRating: Int
    var injuryOccurred: Int
}

struct Statistics {
    var mean: Double
    var median: Double
    var min: Double
    var max: Double
    var stdDev: Double
}

struct DatasetStatistics {
    var totalSamples: Int
    var ageStats: Statistics
    var weightStats: Statistics
    var heightStats: Statistics
    var completionRateStats: Statistics
    var injuryCount: Int
    var fitnessLevelDistribution: [String: Int]
    var durationDistribution: [String: Int]
}
