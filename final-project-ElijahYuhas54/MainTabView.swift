import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var userViewModel = UserViewModel()
    @StateObject private var workoutViewModel = WorkoutViewModel()
    @State private var hasLoadedData = false
    
    var body: some View {
        TabView {
            HomeView()
                .environmentObject(userViewModel)
                .environmentObject(workoutViewModel)
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
            
            WorkoutPlansView()
                .environmentObject(workoutViewModel)
                .environmentObject(userViewModel)
                .tabItem {
                    Label("Plans", systemImage: "list.bullet.clipboard.fill")
                }
            
            ProfileView()
                .environmentObject(userViewModel)
                .environmentObject(authViewModel)
                .tabItem {
                    Label("Profile", systemImage: "person.fill")
                }
            
            ModelEvaluationView()
                .tabItem {
                    Label("ML Model", systemImage: "brain.head.profile")
                }
        }
        .onAppear {
            if !hasLoadedData {
                print("DEBUG: Initial data load")
                userViewModel.fetchUserProfile()
                workoutViewModel.fetchWorkoutPlans()
                hasLoadedData = true
            }
        }
    }
}
