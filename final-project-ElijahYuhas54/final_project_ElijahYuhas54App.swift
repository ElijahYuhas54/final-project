//
//  final_project_ElijahYuhas54App.swift
//  final-project-ElijahYuhas54
//
//  Created by Elijah Yuhas on 11/24/25.
//

import SwiftUI
import FirebaseCore

@main
struct WorkoutAIApp: App {
    @StateObject private var authViewModel = AuthViewModel()
    
    init() {
        FirebaseApp.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authViewModel)
        }
    }
}
