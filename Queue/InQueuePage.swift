import SwiftUI
import Firebase
import UserNotifications

class InQueueManager: ObservableObject {
    @Published var myDestination: String = ""
    @Published var queuePosition: Int = 0
    private let db = Firestore.firestore()
    
    func fetchMyDestination() {
        guard let userID = CoreDataManager.shared.getUserID() else {
            print("User ID is nil according to fetchSelectedDestination")
            return
        }
        
        let userRef = db.collection("users").document(userID)
        
        userRef.getDocument { [weak self] snapshot, error in
            guard let self = self else { return }
            
            if let error = error {
                print("Error fetching user document in fetchSelectedDestination: \(error.localizedDescription)")
                return
            }
            
            guard let userData = snapshot?.data() else {
                print("User document not found in fetchSelectedDestination")
                return
            }
            
            if let selectedDestination = userData["SelectedDestination"] as? String {
                DispatchQueue.main.async {
                    self.myDestination = selectedDestination
                    self.fetchQueuePosition()  // Fetch queue count after setting destination
                }
            } else {
                print("SelectedDestination field not found in user document in fetchSelectedDestination")
            }
        }
    }
    
    func fetchQueuePosition() {
        guard !myDestination.isEmpty else {
            print("Destination is empty in function fetchQueuePosition")
            return
        }
        
        guard let userID = CoreDataManager.shared.getUserID() else {
            print("User ID is nil")
            return
        }
        
        let destinationRef = db.collection("Destinations").document(myDestination)
        
        destinationRef.addSnapshotListener { [weak self] snapshot, error in
            guard let self = self else { return }
            guard let data = snapshot?.data() else {
                print("Error fetching destination document: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            
            guard var queueList = data["QueueList"] as? [DocumentReference] else {
                print("QueueList not found in destination document")
                return
            }
            
            if queueList.count > 1 {
                queueList = Array(queueList.dropFirst())
            } else {
                self.queuePosition = 1
                return
            }
            
            var totalPeopleInQueue = 0
            var foundUser = false
            let group = DispatchGroup()
            
            for userRef in queueList {
                group.enter()
                userRef.getDocument { userSnapshot, error in
                    if let error = error {
                        print("Error fetching user document: \(error.localizedDescription)")
                    } else if let userData = userSnapshot?.data(),
                              let peopleJoining = userData["PeopleJoining"] as? Int {
                        if userSnapshot?.documentID == userID {
                            totalPeopleInQueue += peopleJoining + 1
                            foundUser = true
                        } else {
                            totalPeopleInQueue += peopleJoining
                        }
                    }
                    group.leave()
                }
            }
            
            group.notify(queue: .main) {
                if foundUser {
                    self.queuePosition = totalPeopleInQueue
                }
                
                if self.queuePosition < 30 {
                    self.sendNotification()
                }
            }
        }
    }
    
    func leaveQueue() {
        guard let userID = CoreDataManager.shared.getUserID() else {
            print("User ID is nil")
            return
        }

        let usersRef = Firestore.firestore().collection("users").document(userID)
        usersRef.getDocument { userSnapshot, error in
            if let error = error {
                print("Error fetching user document: \(error.localizedDescription)")
                return
            }

            guard let userData = userSnapshot?.data(),
                  let myDestination = userData["SelectedDestination"] as? String else {
                print("User document does not exist or destination not retrieved")
                return
            }

            let destinationsRef = Firestore.firestore().collection("Destinations").document(myDestination)
            destinationsRef.getDocument { snapshot, error in
                if let error = error {
                    print("Error fetching destination document: \(error.localizedDescription)")
                    return
                }

                guard let data = snapshot?.data(),
                      var queueList = data["QueueList"] as? [DocumentReference] else {
                    print("Queue list not found")
                    return
                }

                let userRefPath = "users/\(userID)"
                if let indexToRemove = queueList.firstIndex(where: { $0.path == userRefPath }) {
                    queueList.remove(at: indexToRemove)

                    destinationsRef.updateData(["QueueList": queueList]) { error in
                        if let error = error {
                            print("Error updating destination document: \(error.localizedDescription)")
                            return
                        }
                        
                        usersRef.delete { error in
                            if let error = error {
                                print("Error deleting user document: \(error.localizedDescription)")
                            } else {
                                print("User document deleted successfully.")
                                self.queuePosition = 0
                            }
                        }
                    }
                } else {
                    print("User reference not found in queueList.")
                }
            }
        }
    }

    func sendNotification() {
        let content = UNMutableNotificationContent()
        content.title = "Queue Update"
        content.body = "Your position in the queue is now \(queuePosition)."
        content.sound = .default
        
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error adding notification: \(error.localizedDescription)")
            }
        }
    }

    func requestNotificationPermission() {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("Notification permission request error: \(error.localizedDescription)")
            } else {
                print("Notification permission granted: \(granted)")
            }
        }
        // Ensure the notification center delegate is set
        center.delegate = UIApplication.shared.delegate as? UNUserNotificationCenterDelegate
    }
}
import SwiftUI

struct InQueuePage: View {
    @StateObject private var inQueueManager = InQueueManager()
    @ObservedObject var refreshManager: RefreshManager
    
    @State private var showingNotificationPopup = false
    @State private var showingConfirmation = false
    @State private var showingReviewPopup = false
    @State private var userComment: String = ""
    @State private var navigateToContentView = false
    @State private var rating: Int = 0
    @State private var showingCommentsPopup = false
    
    var body: some View {
        NavigationView {
            ZStack(alignment: .bottomTrailing) {
                VStack {
                    Text("You are in position \(inQueueManager.queuePosition) of the line for \(inQueueManager.myDestination).")
                        .padding()
                  
                    Text("Please check this page frequently. When your queue position is 30 or less, make your way to the destination. Once you have entered, remember to press the 'Leave' button to officially exit the queue. Thank you!")
                        .font(.footnote)

                    
                    Spacer()
                    
                    Button(action: {
                        showingConfirmation = true
                    }) {
                        Text("Leave the Queue")
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.blue)
                            .cornerRadius(10)
                            .padding(.horizontal)
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
                        ReviewPopup(
                            isPresented: $showingReviewPopup,
                            navigateToContentView: $navigateToContentView,
                            rating: $rating,
                            userComment: $userComment
                        )
                    }
                }
                .navigationBarHidden(true)
                .onAppear {
                    inQueueManager.fetchMyDestination()
                    inQueueManager.requestNotificationPermission()
                    showingNotificationPopup = true
                }
                .onChange(of: inQueueManager.queuePosition) { newValue in
                    print("Queue position updated to \(newValue)")
                }
                .onReceive(refreshManager.$shouldRefresh) { _ in
                    inQueueManager.fetchMyDestination()
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
                    CommentsPopup(isPresented: $showingCommentsPopup, userComment: $userComment)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.black.opacity(0.4).edgesIgnoringSafeArea(.all))
                }
            }
        }
    }

    func leaveQueue() {
        inQueueManager.leaveQueue()
    }
   
    func ReviewPopup(
        isPresented: Binding<Bool>,
        navigateToContentView: Binding<Bool>,
        rating: Binding<Int>,
        userComment: Binding<String>
    ) -> some View {
        VStack(spacing: 20) {
            Text("Rate Your Experience")
                .font(.headline)

            StarRatingView(rating: rating)

            Text("Please share your comments and advice:")
                .font(.subheadline)
                .padding(.top, 10)

            TextField("Enter your comment", text: userComment)
                .frame(height: 100)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
                .padding(.horizontal)

            HStack {
                Button(action: {
                    isPresented.wrappedValue = false
                    navigateToContentView.wrappedValue = true
                    leaveQueue()
                    CoreDataManager.shared.saveUserComment(userComment.wrappedValue)
                    print("User's rating: \(rating.wrappedValue), Comment: \(userComment.wrappedValue)")
                    userComment.wrappedValue = ""
                }) {
                    Text("Leave")
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
                    leaveQueue()
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
    }

    func CommentsPopup(isPresented: Binding<Bool>, userComment: Binding<String>) -> some View {
        VStack {
            Text("Your Comments")
                .font(.headline)

            TextField("Enter your comment", text: userComment)
                .frame(height: 100)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
                .padding()

            HStack {
                Button(action: {
                    isPresented.wrappedValue = false
                }) {
                    Text("Close")
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.red)
                        .cornerRadius(10)
                }
            }
            .padding()
        }
        .background(Color.white)
        .cornerRadius(10)
        .padding()
    }
}

struct StarRatingView: View {
    @Binding var rating: Int

    var body: some View {
        HStack {
            ForEach(1..<6) { star in
                Image(systemName: star <= rating ? "star.fill" : "star")
                    .foregroundColor(star <= rating ? .yellow : .gray)
                    .onTapGesture {
                        rating = star
                    }
            }
        }
    }
}



