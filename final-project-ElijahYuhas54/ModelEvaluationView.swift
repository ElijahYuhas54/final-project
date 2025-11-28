import SwiftUI
import Charts

struct ModelEvaluationView: View {
    @StateObject private var modelService = WorkoutRecommendationModel()
    @StateObject private var dataCollection = DataCollectionService()
    @State private var showingTrainingResults = false
    @State private var isProcessing = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 25) {
                    datasetSection
                    
                    if isProcessing {
                        processingView
                    }
                    
                    trainingSection
                    
                    if let evaluation = modelService.evaluationResults {
                        metricsSection(evaluation)
                        confusionMatrixSection(evaluation)
                    }
                }
                .padding()
            }
            .navigationTitle("Model Evaluation")
            .onAppear {
                dataCollection.fetchAllFeedback()
            }
        }
    }
    
    private var datasetSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Dataset Information")
                .font(.headline)
            
            HStack {
                DataInfoCard(
                    icon: "chart.bar.doc.horizontal",
                    title: "Total Samples",
                    value: "\(dataCollection.feedbackList.count)"
                )
                
                DataInfoCard(
                    icon: "checkmark.circle",
                    title: "Ready",
                    value: dataCollection.feedbackList.isEmpty ? "No" : "Yes"
                )
            }
            
            Button(action: exportDataset) {
                HStack {
                    Image(systemName: "square.and.arrow.up")
                    Text("Export Dataset (CSV)")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue.opacity(0.1))
                .cornerRadius(10)
            }
        }
    }
    
    private var trainingSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Model Training & Testing")
                .font(.headline)
            
            Button(action: startTrainingAndTesting) {
                HStack {
                    Image(systemName: "brain.head.profile")
                    Text("Train & Test Model")
                        .fontWeight(.semibold)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [Color.purple, Color.blue]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(10)
            }
            .disabled(dataCollection.feedbackList.isEmpty || isProcessing)
            
            if !modelService.trainingProgress.isEmpty {
                Text(modelService.trainingProgress)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(10)
            }
        }
    }
    
    private func metricsSection(_ evaluation: ModelEvaluation) -> some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Evaluation Metrics")
                .font(.headline)
            
            VStack(spacing: 12) {
                MetricRow(name: "Accuracy", value: evaluation.accuracy, color: .blue)
                MetricRow(name: "Precision", value: evaluation.precision, color: .green)
                MetricRow(name: "Recall", value: evaluation.recall, color: .orange)
                MetricRow(name: "F1 Score", value: evaluation.f1Score, color: .purple)
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(10)
            
            Text("Total Test Samples: \(evaluation.totalSamples)")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    private func confusionMatrixSection(_ evaluation: ModelEvaluation) -> some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Confusion Matrix")
                .font(.headline)
            
            VStack(spacing: 0) {
                HStack(spacing: 0) {
                    Text("")
                        .frame(width: 80, height: 50)
                    Text("Predicted +")
                        .frame(maxWidth: .infinity)
                        .font(.caption)
                    Text("Predicted -")
                        .frame(maxWidth: .infinity)
                        .font(.caption)
                }
                
                HStack(spacing: 0) {
                    Text("Actual +")
                        .frame(width: 80, height: 80)
                        .font(.caption)
                    
                    ConfusionCell(
                        value: evaluation.confusionMatrix[0][0],
                        label: "TP",
                        color: .green
                    )
                    
                    ConfusionCell(
                        value: evaluation.confusionMatrix[0][1],
                        label: "FP",
                        color: .orange
                    )
                }
                
                HStack(spacing: 0) {
                    Text("Actual -")
                        .frame(width: 80, height: 80)
                        .font(.caption)
                    
                    ConfusionCell(
                        value: evaluation.confusionMatrix[1][0],
                        label: "FN",
                        color: .orange
                    )
                    
                    ConfusionCell(
                        value: evaluation.confusionMatrix[1][1],
                        label: "TN",
                        color: .green
                    )
                }
            }
            .background(Color.white)
            .cornerRadius(10)
            .shadow(radius: 2)
        }
    }
    
    private var processingView: some View {
        VStack(spacing: 15) {
            ProgressView()
                .scaleEffect(1.2)
            Text("Processing model training and testing...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.blue.opacity(0.1))
        .cornerRadius(10)
    }
    
    private func startTrainingAndTesting() {
        isProcessing = true
        
        let preprocessor = DataPreprocessor()
        let cleanedData = preprocessor.cleanAndNormalize(feedbackList: dataCollection.feedbackList)
        let filteredData = preprocessor.removeOutliers(data: cleanedData)
        let balancedData = preprocessor.balanceDataset(data: filteredData)
        let (trainData, testData) = preprocessor.splitTrainTest(data: balancedData, testRatio: 0.2)
        
        Task {
            await modelService.trainModel(trainingData: trainData)
            await modelService.testModel(testData: testData)
            
            await MainActor.run {
                isProcessing = false
            }
        }
    }
    
    private func exportDataset() {
        let csv = dataCollection.exportDatasetToCSV()
        
        let fileName = "workout_dataset_\(Date().timeIntervalSince1970).csv"
        let path = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        
        do {
            try csv.write(to: path, atomically: true, encoding: .utf8)
            
            let activityVC = UIActivityViewController(activityItems: [path], applicationActivities: nil)
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let rootVC = windowScene.windows.first?.rootViewController {
                rootVC.present(activityVC, animated: true)
            }
        } catch {
            print("Error exporting CSV: \(error)")
        }
    }
}

struct DataInfoCard: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        VStack {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.headline)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(10)
    }
}

struct MetricRow: View {
    let name: String
    let value: Double
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(name)
                    .font(.subheadline)
                
                Spacer()
                
                Text(String(format: "%.2f%%", value * 100))
                    .font(.headline)
                    .foregroundColor(color)
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 8)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(color)
                        .frame(width: geometry.size.width * value, height: 8)
                }
            }
            .frame(height: 8)
        }
    }
}

struct ConfusionCell: View {
    let value: Int
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 5) {
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
            
            Text("\(value)")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(color.opacity(0.1))
    }
}
