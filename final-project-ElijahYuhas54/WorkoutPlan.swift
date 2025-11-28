import Foundation
import FirebaseFirestore

enum WorkoutDuration: String, Codable, CaseIterable {
    case day = "Day"
    case week = "Week"
    case month = "Month"
    case year = "Year"
}

struct WorkoutPlan: Codable, Identifiable {
    @DocumentID var id: String?
    var userId: String
    var duration: String
    var plan: String
    var createdAt: Date
    var userWeight: Double
    var userHeight: Double
    var userAge: Int
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId
        case duration
        case plan
        case createdAt
        case userWeight
        case userHeight
        case userAge
    }
}
