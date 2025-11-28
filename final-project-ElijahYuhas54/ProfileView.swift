import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var userViewModel: UserViewModel
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var showingEditProfile = false
    @State private var showingSignOutAlert = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 25) {
                    profileHeader
                    
                    if let profile = userViewModel.userProfile {
                        profileDetails(profile)
                    } else {
                        noProfileView
                    }
                    
                    actionButtons
                }
                .padding()
            }
            .navigationTitle("Profile")
            .sheet(isPresented: $showingEditProfile) {
                if userViewModel.userProfile != nil {
                    EditProfileView()
                        .environmentObject(userViewModel)
                } else {
                    ProfileSetupView()
                        .environmentObject(userViewModel)
                }
            }
            .alert("Sign Out", isPresented: $showingSignOutAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Sign Out", role: .destructive) {
                    authViewModel.signOut()
                }
            } message: {
                Text("Are you sure you want to sign out?")
            }
        }
    }
    
    private var profileHeader: some View {
        VStack(spacing: 15) {
            ZStack {
                Circle()
                    .fill(LinearGradient(
                        gradient: Gradient(colors: [Color.blue, Color.purple]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 100, height: 100)
                
                Image(systemName: "person.fill")
                    .font(.system(size: 50))
                    .foregroundColor(.white)
            }
            
            if let email = authViewModel.currentUser?.email {
                Text(email)
                    .font(.headline)
            }
        }
    }
    
    private func profileDetails(_ profile: UserProfile) -> some View {
        VStack(spacing: 15) {
            ProfileDetailRow(icon: "scalemass.fill", title: "Weight", value: "\(Int(profile.weight)) kg")
            ProfileDetailRow(icon: "ruler.fill", title: "Height", value: "\(Int(profile.height)) cm")
            ProfileDetailRow(icon: "calendar", title: "Age", value: "\(profile.age) years")
            ProfileDetailRow(icon: "figure.strengthtraining.traditional", title: "Fitness Level", value: profile.fitnessLevel)
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "target")
                        .foregroundColor(.blue)
                        .frame(width: 30)
                    Text("Goals")
                        .fontWeight(.semibold)
                }
                
                Text(profile.goals)
                    .foregroundColor(.secondary)
                    .padding(.leading, 38)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(10)
        }
    }
    
    private var noProfileView: some View {
        VStack(spacing: 15) {
            Image(systemName: "person.crop.circle.badge.exclamationmark")
                .font(.system(size: 60))
                .foregroundColor(.orange)
            
            Text("No Profile Set Up")
                .font(.headline)
            
            Text("Create your profile to start generating personalized workout plans")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal)
        }
        .padding(.vertical, 30)
    }
    
    private var actionButtons: some View {
        VStack(spacing: 15) {
            Button(action: { showingEditProfile = true }) {
                HStack {
                    Image(systemName: userViewModel.userProfile == nil ? "plus.circle.fill" : "pencil.circle.fill")
                    Text(userViewModel.userProfile == nil ? "Create Profile" : "Edit Profile")
                        .fontWeight(.semibold)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(Color.blue)
                .cornerRadius(10)
            }
            
            Button(action: { showingSignOutAlert = true }) {
                HStack {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                    Text("Sign Out")
                        .fontWeight(.semibold)
                }
                .foregroundColor(.red)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(Color.red.opacity(0.1))
                .cornerRadius(10)
            }
        }
        .padding(.top, 20)
    }
}

struct ProfileDetailRow: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 30)
            
            Text(title)
                .fontWeight(.semibold)
            
            Spacer()
            
            Text(value)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(10)
    }
}
