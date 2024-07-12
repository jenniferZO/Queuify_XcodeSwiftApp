//
//  InQueuePage2.swift
//  Queue
//
//  Created by Zhao, Jennifer (OXF) Student on 09/07/2024.
//

import Foundation
import SwiftUI
import Firebase
import UserNotifications

struct InQueuePage: View {
    @ObservedObject var refreshManager: RefreshManager
    @State private var queuePosition: Int?
    @State private var showingConfirmation = false
    @State private var showingReviewPopup = false
    @State private var userComment: String = ""
    @State private var navigateToContentView = false
    @State private var rating: Int = 0
    @State private var showingCommentsPopup = false
    var user: User

    var body: some View {
        NavigationView {
            ZStack(alignment: .bottomTrailing) {
                VStack {
                    if let queuePosition = queuePosition {
                        Text("You are in position \(queuePosition) of the line.")
                            .padding()
                    } else {
                        ProgressView("Calculating queue position...")
                            .progressViewStyle(CircularProgressViewStyle())
                            .padding()
                    }

                    Text("Please click the refresh button below to see your current position.")
                        .font(.footnote)

                    Spacer()

                    Button(action: {
                        showingConfirmation = true
                    }) {
                        HStack {
                            Text("Leave the Queue")
                                .foregroundColor(.white)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.blue)
                                .cornerRadius(10)
                                .padding(.horizontal)
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                    .alert(isPresented: $showingConfirmation) {
                        Alert(
                            title: Text("Are you sure you want to leave the queue?"),
                            primaryButton: .default(Text("Yes")) {
                                leaveQueue()
                                showingReviewPopup = true
                            },
                            secondaryButton: .cancel(Text("No"))
                        )
                    }

                    NavigationLink(destination: WelcomePage(refreshManager: refreshManager), isActive: $navigateToContentView) {
                        EmptyView()
                    }
                    .hidden()

                    if showingReviewPopup {
                        ReviewPopup(isPresented: $showingReviewPopup, navigateToContentView: $navigateToContentView, rating: $rating, userComment: $userComment)
                    }
                }
                .navigationBarHidden(true)
                .onAppear {
                    requestNotificationPermission()
                    fetchQueuePosition()
                    startFetchingQueuePositionPeriodically()
                    startListeningToQueueListChanges() // Start listening to Firestore changes
                }
                .onReceive(refreshManager.$shouldRefresh) { _ in
                    fetchQueuePosition()
                }

                Button(action: {
                    showingCommentsPopup = true
                }) {
                    Image(systemName: "message.circle.fill")
                        .font(.system(size: 32))
                        .foregroundColor(.blue)
                        .padding()
                }
                .buttonStyle(PlainButtonStyle())
                .offset(x: -16, y: -50)

                if showingCommentsPopup {
                    CommentsPopup(isPresented: $showingCommentsPopup)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.black.opacity(0.4).edgesIgnoringSafeArea(.all))
                }
            }
        }
    }

    // Request notification permission if not granted
    func requestNotificationPermission() {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("Notification permission request error: \(error.localizedDescription)")
            }
        }
    }

// Fetch queue position from Firestore
func fetchQueuePosition() {
    // Get the current user's ID from Core Data
    guard let userID = CoreDataManager.shared.getUserID() else {
        print("User ID is nil")
        return
    }

    // Get Firestore instance
    let db = Firestore.firestore()
    // Reference to the 'destinations' collection
    let destinationsRef = db.collection("destinations")

    // Query Firestore for documents where 'name' field matches user's destination
    destinationsRef.whereField("name", isEqualTo: user.destination).getDocuments { snapshot, error in
        // Handle any errors that occur during fetching
        if let error = error {
            print("Error fetching destinations: \(error.localizedDescription)")
            return
        }

        // Ensure there are documents in the snapshot
        guard let snapshot = snapshot else {
            print("No matching destination found")
            return
        }

        // Initialize variables to track total people before user and user's queue position
        var totalPeopleBeforeUser = 0
        var queuePosition: Int?

        // Iterate through each document in the snapshot
        for document in snapshot.documents {
            // Extract the 'queueList' array from document data
            if let queueList = document.data()["queueList"] as? [[String: Any]] {
                // Iterate through each user data entry in the 'queueList'
                for userData in queueList {
                    // Extract 'peopleJoining' value and guard against non-integer values
                    guard let peopleJoining = userData["peopleJoining"] as? Int else {
                        continue
                    }
                    // Accumulate total people before the current user
                    totalPeopleBeforeUser += peopleJoining

                    // Check if the 'userID' in current userData matches logged-in user's ID
                    if let queueUserID = userData["userID"] as? String, queueUserID == userID {
                        // Calculate the user's queue position and break out of loop
                        queuePosition = totalPeopleBeforeUser + 1
                        break
                    }
                }
            }

            // If queuePosition is found, exit the loop
            if queuePosition != nil {
                break
            }
        }

        // Update UI on the main thread with the fetched queue position
        DispatchQueue.main.async {
            self.queuePosition = queuePosition
            // If user's position is within top 30, send a notification
            if let position = queuePosition, position < 31 {
                sendNotification()
            }
        }
    }
}



    // Send notification to user
    func sendNotification() {
        let content = UNMutableNotificationContent()
        content.title = "Queue Update"
        content.body = "You are coming to the end of the queue, please come back."
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error adding notification: \(error.localizedDescription)")
            }
        }
    }

    // Start periodically fetching queue position
    func startFetchingQueuePositionPeriodically() {
        Timer.scheduledTimer(withTimeInterval: 10, repeats: true) { timer in
            fetchQueuePosition()
        }
    }

    // Start listening to Firestore document changes for queueList
    func startListeningToQueueListChanges() {
        guard let userID = Auth.auth().currentUser?.uid else {
            print("User ID is nil")
            return
        }

        let db = Firestore.firestore()
        let destinationsRef = db.collection("destinations")

        // Listen to changes in the specific destination document
        let listener = destinationsRef.whereField("name", isEqualTo: user.destination)
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    print("Error listening to destinations: \(error.localizedDescription)")
                    return
                }

                guard let snapshot = snapshot else {
                    print("No matching destination found")
                    return
                }

                var totalPeopleBeforeUser = 0
                var queuePosition: Int?

                for document in snapshot.documents {
                    if let queueList = document.data()["queueList"] as? [[String: Any]] {
                        for userData in queueList {
                            guard let peopleJoining = userData["peopleJoining"] as? Int else {
                                continue
                            }
                            totalPeopleBeforeUser += peopleJoining

                            if let queueUserID = userData["userID"] as? String, queueUserID == userID {
                                queuePosition = totalPeopleBeforeUser + 1
                                break
                            }
                        }
                    }

                    if queuePosition != nil {
                        break
                    }
                }

                DispatchQueue.main.async {
                    self.queuePosition = queuePosition
                    if let position = queuePosition, position < 31 {
                        sendNotification()
                    }
                }
            }

        // Store the listener to remove it when necessary (e.g., when leaving view)
        // This ensures we don't have unnecessary listeners active.
        // Example: FirestoreUtils.shared.listeners.append(listener)
    }


// Leave the queue by removing user from queueList in Firestore
func leaveQueue() {
    // Get the current user's ID from Core Data
    guard let userID = CoreDataManager.shared.getUserID() else {
        print("User ID is nil")
        return
    }

    // Get Firestore instance
    let db = Firestore.firestore()
    // Reference to the 'destinations' collection
    let destinationsRef = db.collection("destinations")

    // Query Firestore for documents where 'name' field matches user's destination
    destinationsRef.whereField("name", isEqualTo: user.destination).getDocuments { snapshot, error in
        // Handle any errors that occur during fetching
        if let error = error {
            print("Error fetching destinations: \(error.localizedDescription)")
            return
        }

        // Ensure there are documents in the snapshot
        guard let snapshot = snapshot else {
            print("No matching destination found")
            return
        }

        // Iterate through each document in the snapshot
        for document in snapshot.documents {
            // Extract the 'queueList' array from document data
            if var queueList = document.data()["queueList"] as? [[String: Any]] {
                // Find index of the user's data in the 'queueList'
                if let indexToRemove = queueList.firstIndex(where: { userData in
                    if let queueUserID = userData["userID"] as? String {
                        return queueUserID == userID
                    }
                    return false
                }) {
                    // Remove user's data from 'queueList'
                    queueList.remove(at: indexToRemove)

                    // Update positions for subsequent users in the queue
                    for index in indexToRemove..<queueList.count {
                        if var userData = queueList[index] as? [String: Any] {
                            if let currentPos = userData["position"] as? Int {
                                userData["position"] = currentPos - 1
                                queueList[index] = userData
                            }
                        }
                    }

                    // Update Firestore document with modified 'queueList'
                    document.reference.updateData(["queueList": queueList]) { error in
                        if let error = error {
                            print("Error leaving queue: \(error.localizedDescription)")
                        } else {
                            print("Left the queue successfully.")
                            // Reset queuePosition after leaving
                            self.queuePosition = nil
                        }
                    }
                } else {
                    print("User data not found in queueList.")
                }
            }
        }
    }
}


    // Review popup view
    func ReviewPopup(isPresented: Binding<Bool>, navigateToContentView: Binding<Bool>, rating: Binding<Int>, userComment: Binding<String>) -> some View {
        VStack(spacing: 20) {
            Text("Rate Your Experience")
                .font(.headline)
            StarRatingView(rating: rating)

            Text("Please share your comments")
                .font(.subheadline)
                .padding(.top, 10)
            Text("and advice:")
                .font(.subheadline)
                .multilineTextAlignment(.leading)

            TextField("Enter your comment", text: userComment)
                .frame(height: 100)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
                .padding(.horizontal)

            HStack {
                Button(action: {
                    isPresented.wrappedValue = false
                    navigateToContentView.wrappedValue = true
                    CoreDataManager.shared.saveUserComment(userComment.wrappedValue)
                    print("User's rating: \(rating.wrappedValue), Comment: \(userComment.wrappedValue)")
                    userComment.wrappedValue = ""
                }) {
                    Text("Submit")
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .cornerRadius(10)
                        .padding(.horizontal)
                }

                Button(action: {
                    isPresented.wrappedValue = false
                    navigateToContentView.wrappedValue = true
                }) {
                    Text("Skip")
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.gray)
                        .cornerRadius(10)
                        .padding(.horizontal)
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(10)
        .shadow(radius: 10)
        .padding(.horizontal, 40)
    }

    // Star rating view
    func StarRatingView(rating: Binding<Int>) -> some View {
        HStack {
            ForEach(1..<6) { star in
                Image(systemName: star <= rating.wrappedValue ? "star.fill" : "star")
                    .foregroundColor(.yellow)
                    .onTapGesture {
                        rating.wrappedValue = star
                    }
            }
        }
    }

    // Comments popup view
    func CommentsPopup(isPresented: Binding<Bool>) -> some View {
        VStack {
            Text("Comments")
                .font(.headline)
                .padding()

            TextField("Enter your comment", text: .constant(""))
                .frame(height: 100)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
                .padding(.horizontal)

            Button(action: {
                isPresented.wrappedValue = false
            }) {
                Text("Close")
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .cornerRadius(10)
                    .padding(.horizontal)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(10)
        .shadow(radius: 10)
        .padding(.horizontal, 40)
    }
}




