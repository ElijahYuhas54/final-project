import Foundation
import FirebaseFirestore
import FirebaseAuth

class UserViewModel: ObservableObject {
    @Published var userProfile: UserProfile?
    @Published var isLoading = false
    @Published var errorMessage = ""
    
    private let db = Firestore.firestore()
    
    func fetchUserProfile() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        isLoading = true
        
        db.collection("users").document(userId).getDocument { [weak self] snapshot, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                if let error = error {
                    self?.errorMessage = error.localizedDescription
                    return
                }
                
                if let snapshot = snapshot, snapshot.exists {
                    do {
                        self?.userProfile = try snapshot.data(as: UserProfile.self)
                    } catch {
                        self?.errorMessage = "Error decoding user profile: \(error.localizedDescription)"
                    }
                }
            }
        }
    }
    
    func saveUserProfile(weight: Double, height: Double, age: Int, fitnessLevel: String, goals: String) {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        isLoading = true
        
        let profile = UserProfile(
            userId: userId,
            weight: weight,
            height: height,
            age: age,
            fitnessLevel: fitnessLevel,
            goals: goals,
            createdAt: Date()
        )
        
        do {
            try db.collection("users").document(userId).setData(from: profile) { [weak self] error in
                DispatchQueue.main.async {
                    self?.isLoading = false
                    if let error = error {
                        self?.errorMessage = error.localizedDescription
                    } else {
                        self?.userProfile = profile
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
    
    func updateUserProfile(weight: Double, height: Double, age: Int, fitnessLevel: String, goals: String) {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        isLoading = true
        
        let data: [String: Any] = [
            "weight": weight,
            "height": height,
            "age": age,
            "fitnessLevel": fitnessLevel,
            "goals": goals
        ]
        
        db.collection("users").document(userId).updateData(data) { [weak self] error in
            DispatchQueue.main.async {
                self?.isLoading = false
                if let error = error {
                    self?.errorMessage = error.localizedDescription
                } else {
                    self?.fetchUserProfile()
                }
            }
        }
    }
}
