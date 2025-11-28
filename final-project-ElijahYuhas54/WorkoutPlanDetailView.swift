import SwiftUI

struct WorkoutPlanDetailView: View {
    let plan: WorkoutPlan
    @State private var showingShareSheet = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                planHeader
                
                Divider()
                
                planContent
            }
            .padding()
        }
        .navigationTitle("Workout Plan")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showingShareSheet = true }) {
                    Image(systemName: "square.and.arrow.up")
                }
            }
        }
        .sheet(isPresented: $showingShareSheet) {
            ShareSheet(items: [plan.plan])
        }
        .onAppear {
            print("DEBUG: WorkoutPlanDetailView appeared")
            print("DEBUG: Plan ID: \(plan.id ?? "no ID")")
            print("DEBUG: Plan duration: \(plan.duration)")
            print("DEBUG: Plan content length: \(plan.plan.count) characters")
            print("DEBUG: Plan preview: \(plan.plan.prefix(100))...")
        }
    }
    
    private var planHeader: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Image(systemName: "calendar.badge.clock")
                    .font(.title2)
                    .foregroundColor(.blue)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(plan.duration)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Generated on \(formatDate(plan.createdAt))")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            
            HStack(spacing: 20) {
                DetailItem(icon: "person.fill", label: "Age", value: "\(plan.userAge) years")
                DetailItem(icon: "scalemass.fill", label: "Weight", value: "\(Int(plan.userWeight)) kg")
                DetailItem(icon: "ruler.fill", label: "Height", value: "\(Int(plan.userHeight)) cm")
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(10)
        }
    }
    
    private var planContent: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Your Workout Plan")
                .font(.headline)
            
            if plan.plan.isEmpty {
                Text("No workout plan content available")
                    .foregroundColor(.red)
                    .padding()
            } else {
                MarkdownText(text: plan.plan)
                    .font(.body)
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct DetailItem: View {
    let icon: String
    let label: String
    let value: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.blue)
            
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
        }
        .frame(maxWidth: .infinity)
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
