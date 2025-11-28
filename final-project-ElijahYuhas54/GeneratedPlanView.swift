import SwiftUI

struct GeneratedPlanView: View {
    let plan: String
    @Environment(\.dismiss) var dismiss
    @State private var showingShareSheet = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    successBanner
                    
                    Divider()
                    
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Your Personalized Workout Plan")
                            .font(.headline)
                        
                        MarkdownText(text: plan)
                            .font(.body)
                    }
                    .padding()
                }
            }
            .navigationTitle("Generated Plan")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingShareSheet = true }) {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
            }
            .sheet(isPresented: $showingShareSheet) {
                ShareSheet(items: [plan])
            }
        }
    }
    
    private var successBanner: some View {
        HStack {
            Image(systemName: "checkmark.circle.fill")
                .font(.title)
                .foregroundColor(.green)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Plan Generated!")
                    .font(.headline)
                
                Text("Your workout plan has been saved")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding()
        .background(Color.green.opacity(0.1))
        .cornerRadius(10)
        .padding()
    }
}
