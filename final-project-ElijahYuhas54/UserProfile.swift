import Foundation
import FirebaseFirestore

struct UserProfile: Codable, Identifiable {
    @DocumentID var id: String?
    var userId: String
    var weight: Double
    var height: Double
    var age: Int
    var fitnessLevel: String
    var goals: String
    var createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId
        case weight
        case height
        case age
        case fitnessLevel
        case goals
        case createdAt
    }
}
