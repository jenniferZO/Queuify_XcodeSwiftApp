//
//  ContentView.swift
//  Queue
//
//  Created by Zhao, Jennifer (OXF) Student on 26/06/2024.
//

import SwiftUI
import Firebase
import FirebaseDatabase

struct User {
    let userID: String
    var destination: String // Make destination mutable
    var peopleJoining: Int // Make peopleJoining mutable
    // Add more properties as needed
}

struct ContentView: View {
    @ObservedObject var refreshManager: RefreshManager
    @State private var queuePosition = CoreDataManager.shared.getQueueCount()
    @State private var peopleJoining = CoreDataManager.shared.getPeopleJoining() ?? 0
    @State private var user: User?

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

                if let user = user {
                    NavigationLink(destination: HomePage(refreshManager: refreshManager, userID: user.userID)) {
                        HStack {
                            Spacer()
                            Text("Join a Queue")
                                .foregroundColor(.white)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.blue)
                                .cornerRadius(10)
                                .padding(.horizontal)
                                .onTapGesture {
                                    generateAndSaveUser()
                                }
                        }
                    }
                } else {
                    Button(action: {
                        generateAndSaveUser()
                    }) {
                        HStack {
                            Spacer()
                            Text("Join a Queue")
                                .foregroundColor(.white)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.blue)
                                .cornerRadius(10)
                                .padding(.horizontal)
                        }
                    }
                }

                NavigationLink(destination: StartQueuePage()) {
                    HStack {
                        Spacer()
                        Text("Start a Queue")
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.blue)
                            .cornerRadius(10)
                            .padding(.horizontal)
                    }
                }

                Spacer()
            }
            .onReceive(refreshManager.$shouldRefresh) { _ in
                // Update queuePosition when returning from InQueuePage
                queuePosition = CoreDataManager.shared.getQueueCount()
            }
        }
        .navigationBarHidden(true)
    }

    // Function to generate a unique 8-digit user ID
    func generateUniqueUserID() -> String {
        let userID = String(format: "%08d", arc4random_uniform(100_000_000))
        return userID
    }

    // Function to generate and save user to Firebase
    func generateAndSaveUser() {
        let userID = generateUniqueUserID()
        let destination = "" // Initial empty string
        let peopleJoining = 0 // Initial 0

        // Create user object with placeholder values
        var newUser = User(userID: userID, destination: destination, peopleJoining: peopleJoining)

        // Save user to Firebase
        let ref = Database.database().reference().child("Users").child(userID)
        ref.setValue([
            "userID": newUser.userID,
            "destination": newUser.destination,
            "peopleJoining": newUser.peopleJoining
        ]) { error, _ in
            if let error = error {
                print("Error saving user to Firebase: \(error.localizedDescription)")
            } else {
                print("User \(newUser.userID) saved successfully.")
                self.user = newUser // Set the generated user
            }
        }

        // Update user destination and peopleJoining later
        // For example:
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            // Simulating a delay, replace with actual logic
            newUser.destination = "Shop"
            newUser.peopleJoining = 1
            
            // Update Firebase with new values
            ref.updateChildValues([
                "destination": newUser.destination,
                "peopleJoining": newUser.peopleJoining
            ]) { error, _ in
                if let error = error {
                    print("Error updating destination and peopleJoining in Firebase: \(error.localizedDescription)")
                } else {
                    print("Destination and peopleJoining updated successfully.")
                    self.user = newUser // Update local state with new values
                }
            }
        }
    }
}
