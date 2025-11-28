import SwiftUI

struct WorkoutPlansView: View {
    @EnvironmentObject var workoutViewModel: WorkoutViewModel
    @EnvironmentObject var userViewModel: UserViewModel
    @State private var feedbackPlan: WorkoutPlan?
    @State private var showingDeleteAlert = false
    @State private var planToDelete: WorkoutPlan?
    
    var body: some View {
        NavigationView {
            Group {
                if workoutViewModel.isLoading {
                    ProgressView("Loading plans...")
                } else if workoutViewModel.workoutPlans.isEmpty {
                    emptyStateView
                } else {
                    plansList
                }
            }
            .navigationTitle("Workout Plans")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        print("DEBUG: Refresh button tapped")
                        workoutViewModel.fetchWorkoutPlans()
                    }) {
                        Image(systemName: "arrow.clockwise")
                    }
                    .disabled(workoutViewModel.isLoading)
                }
            }
            .fullScreenCover(item: $feedbackPlan) { plan in
                WorkoutFeedbackView(workoutPlan: plan)
                    .environmentObject(userViewModel)
            }
            .alert("Delete Plan", isPresented: $showingDeleteAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    if let plan = planToDelete {
                        workoutViewModel.deleteWorkoutPlan(plan)
                    }
                }
            } message: {
                Text("Are you sure you want to delete this workout plan?")
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 80))
                .foregroundColor(.gray)
            
            Text("No Workout Plans Yet")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Generate your first personalized workout plan from the Home tab")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal)
        }
        .padding()
    }
    
    private var plansList: some View {
        List {
            ForEach(workoutViewModel.workoutPlans) { plan in
                NavigationLink(destination: WorkoutPlanDetailView(plan: plan)) {
                    WorkoutPlanCard(plan: plan, onFeedbackTap: {
                        print("DEBUG: Feedback button tapped from card")
                        print("DEBUG: Plan ID: \(plan.id ?? "no ID")")
                        feedbackPlan = plan
                        print("DEBUG: feedbackPlan set to: \(feedbackPlan?.id ?? "nil")")
                    })
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    Button(role: .destructive) {
                        planToDelete = plan
                        showingDeleteAlert = true
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
                .swipeActions(edge: .leading, allowsFullSwipe: false) {
                    Button {
                        print("DEBUG: Feedback swiped")
                        print("DEBUG: Plan ID: \(plan.id ?? "no ID")")
                        feedbackPlan = plan
                        print("DEBUG: feedbackPlan set to: \(feedbackPlan?.id ?? "nil")")
                    } label: {
                        Label("Feedback", systemImage: "star.fill")
                    }
                    .tint(.orange)
                }
            }
        }
        .listStyle(InsetGroupedListStyle())
        .refreshable {
            workoutViewModel.fetchWorkoutPlans()
        }
    }
}

struct WorkoutPlanCard: View {
    let plan: WorkoutPlan
    let onFeedbackTap: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "calendar.badge.clock")
                    .foregroundColor(.blue)
                
                Text(plan.duration)
                    .font(.headline)
                    .foregroundColor(.blue)
                
                Spacer()
                
                Text(formatDate(plan.createdAt))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            HStack(spacing: 15) {
                InfoPill(icon: "person.fill", text: "\(plan.userAge) yrs")
                InfoPill(icon: "scalemass.fill", text: "\(Int(plan.userWeight)) kg")
                InfoPill(icon: "ruler.fill", text: "\(Int(plan.userHeight)) cm")
            }
            
            Text(plan.plan)
                .lineLimit(3)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding(.top, 5)
            
            HStack {
                Button(action: onFeedbackTap) {
                    HStack {
                        Image(systemName: "star.fill")
                            .font(.caption)
                        Text("Give Feedback")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.orange)
                    .cornerRadius(8)
                }
                .buttonStyle(PlainButtonStyle())
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
        .padding(.vertical, 8)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}

struct InfoPill: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
            Text(text)
                .font(.caption)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.blue.opacity(0.1))
        .cornerRadius(8)
    }
}
