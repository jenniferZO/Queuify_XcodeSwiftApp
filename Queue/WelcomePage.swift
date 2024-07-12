//
//  ContentView.swift
//  Queue
//
//  Created by Zhao, Jennifer (OXF) Student on 26/06/2024.
//
import SwiftUI

struct User {
    var peopleJoining: Int
    var userID: String
    var destination: String
}


struct WelcomePage: View {
    @ObservedObject var refreshManager: RefreshManager
    @State private var user: User?
    @State private var navigateToHomePage = false
    @State private var navigateToStartPage = false
    
    private let coreDataManager = CoreDataManager.shared
    
    // Public initializer
    init(refreshManager: RefreshManager) {
        self.refreshManager = refreshManager
    }
    
    var body: some View {
        NavigationView {
            VStack {
                Spacer()
                Text("👋 Welcome!") // Waving hand emoji with Welcome text
                Spacer()
                
                NavigationLink(destination: HomePage(refreshManager: refreshManager, userID: user?.userID ?? ""), isActive: $navigateToHomePage) {
                    EmptyView()
                }
                JoinQueueButton(title: "Join a Queue") {
                    generateAndSaveUser {
                        // Navigate only after user is saved
                        navigateToHomePage = true
                    }
                }
                
                NavigationLink(destination: StartQueuePage(), isActive: $navigateToStartPage) {
                    EmptyView()
                }
                JoinQueueButton(title: "Start a Queue", backgroundColor: .green) {
                    navigateToStartPage = true
                    // Handle action if needed
                }
                
                Spacer()
            }
            .onAppear {
                if let userID = coreDataManager.getUserID() {
                    self.user = User(peopleJoining: 0, userID: userID, destination: "")
                }
            }
            .onReceive(refreshManager.$shouldRefresh) { _ in
                // Update any necessary state here when refreshing
            }
        }
        .navigationBarHidden(true)
    }
    
    // Function to generate a unique 8-digit user ID
    func generateUniqueUserID() -> String {
        let userID = String(format: "%08d", Int.random(in: 0..<100000000))
        return userID
    }
    
    func generateAndSaveUser(completion: @escaping () -> Void) {
        let userID = generateUniqueUserID()
        coreDataManager.saveUserIDToCoreData(userID: userID) // Save userID to Core Data
        let newUser = User(peopleJoining: 0, userID: userID, destination: "")
        self.user = newUser
        completion()
    }
}

// Custom Button View for JoinQueueButton
struct JoinQueueButton: View {
    var title: String
    var backgroundColor: Color = .blue
    var action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Spacer()
                Text(title)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(backgroundColor)
                    .cornerRadius(10)
                    .padding(.horizontal)
            }
        }
    }
}

