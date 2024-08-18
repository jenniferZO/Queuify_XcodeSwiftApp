import SwiftUI
import FirebaseFirestore
import CoreData

class QueueDisplayViewModel: ObservableObject {
    var db: Firestore
    @Published var queueCount: Int = 2
    @Published var Currentdestination: String = ""
    @Published var peopleJoining: Int = 0
    var userID: String {
        didSet {
            print("User set: \(String(describing: userID))")
        }
    }
    
    private var viewContext: NSManagedObjectContext
    
    init(viewContext: NSManagedObjectContext, initialUserID: String) {
        self.viewContext = viewContext
        self.db = Firestore.firestore()
        self.userID = initialUserID
        // Use a closure to perform additional setup after initialization
        self.initializeProperties()
    }
    
    private func initializeProperties() {
        fetchSelectedDestination()
    }
    
    func getUserID() -> String? {
        let fetchRequest: NSFetchRequest<UserEntity> = UserEntity.fetchRequest()
        
        do {
            let users = try viewContext.fetch(fetchRequest)
            return users.first?.userIDE
        } catch {
            print("Failed to fetch userID from Core Data: \(error.localizedDescription)")
            return nil
        }
    }
    
    func fetchSelectedDestination() {
        guard let userID = getUserID() else {
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
                    self.Currentdestination = selectedDestination
                    self.fetchQueueCount()  // Fetch queue count after setting destination
                }
            } else {
                print("SelectedDestination field not found in user document in fetchSelectedDestination")
            }
        }
    }
    
    func fetchQueueCount() {
        guard !Currentdestination.isEmpty else {
            print("Destination is empty in function fetchQueueCount")
            return
        }
        
        let destinationRef = db.collection("Destinations").document(Currentdestination)
        
        destinationRef.addSnapshotListener { snapshot, error in
            guard let data = snapshot?.data() else {
                print("Error fetching destination document: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            
            guard let queueList = data["QueueList"] as? [DocumentReference] else {
                print("QueueList not found in destination document")
                return
            }
            
            var totalPeopleInQueue = 0
            let group = DispatchGroup()
            
            for userRef in queueList {
                group.enter()
                userRef.getDocument { userSnapshot, error in
                    if let error = error {
                        print("Error fetching user document: \(error.localizedDescription)")
                    } else if let userData = userSnapshot?.data(),
                              let peopleJoining = userData["PeopleJoining"] as? Int {
                        totalPeopleInQueue += peopleJoining
                    }
                    group.leave()
                }
            }
            
            group.notify(queue: .main) {
                self.queueCount = totalPeopleInQueue
            }
        }
    }
    
    func fetchPeopleJoining(completion: @escaping () -> Void) {
        guard let userID = getUserID() else {
            print("User ID is nil in fetchPeopleJoining")
            return
        }
        
        let userRef = db.collection("users").document(userID)
        
        userRef.getDocument { [weak self] snapshot, error in
            guard let self = self else { return }
            
            if let error = error {
                print("Error fetching user document in fetchPeopleJoining: \(error.localizedDescription)")
                return
            }
            
            guard let userData = snapshot?.data(), let peopleJoining = userData["peopleJoining"] as? Int else {
                print("User document or peopleJoining field not found in fetchPeopleJoining")
                return
            }
            
            DispatchQueue.main.async {
                self.peopleJoining = peopleJoining
                completion()
            }
        }
    }
    
    func joinQueue() {
        guard let userID = getUserID(), !Currentdestination.isEmpty else {
            print("User ID or Destination is nil in joinQueue")
            return
        }

        let userRef = db.collection("users").document(userID)

        userRef.getDocument { [weak self] userDocument, error in
            guard let self = self else { return }

            if let error = error {
                print("Error fetching user document in joinQueue: \(error.localizedDescription)")
                return
            }

            guard let userData = userDocument?.data() else {
                print("User document not found in joinQueue")
                return
            }

            if let userDestination = userData["SelectedDestination"] as? String {
                // Ensure Currentdestination is updated before joining queue
                self.Currentdestination = userDestination
                
                // Creating a reference to the destination document
                let destinationRef = self.db.collection("Destinations").document(self.Currentdestination)
                
                // Check if the destination document exists before updating
                destinationRef.getDocument { snapshot, error in
                    if let error = error {
                        print("Error checking destination document existence: \(error.localizedDescription)")
                        return
                    }
                    
                    // Safely unwrap the optional `exists` property
                    guard let exists = snapshot?.exists, exists else {
                        print("Destination document does not exist")
                        return
                    }
                    
                    // Creating a reference to the QueueList array field in the destination document
                    destinationRef.updateData([
                        "QueueList": FieldValue.arrayUnion([userRef]) // Add user reference to QueueList array
                    ]) { error in
                        if let error = error {
                            print("Error joining queue: \(error.localizedDescription)")
                        } else {
                            print("User \(userID) joined the queue successfully.")
                            self.fetchQueueCount()  // Fetch updated queue count after joining
                        }
                    }
                }
            } else {
                print("Destination field not found in user document in joinQueue")
            }
        }
    }
    
    func deleteUserDocument(completion: @escaping () -> Void) {
        guard let userID = getUserID() else {
            print("User ID is nil in deleteUserDocument")
            return
        }
        
        let userRef = db.collection("users").document(userID)
        
        userRef.delete { error in
            if let error = error {
                print("Error deleting user document: \(error.localizedDescription)")
            } else {
                print("User document deleted successfully")
                completion()
            }
        }
    }
}

import SwiftUI
import CoreData
import FirebaseFirestore

struct QueueDisplay: View {
    @Environment(\.managedObjectContext) private var viewContext
    @ObservedObject var viewModel: QueueDisplayViewModel
    var refreshManager: RefreshManager
    var userID: String
    
    @State private var navigateToQueuePage = false
    @State private var showPopup = false
    @State private var navigateToWelcomePage = false
    
    init(viewContext: NSManagedObjectContext, refreshManager: RefreshManager, userID: String) {
        self.userID = userID
        self.viewModel = QueueDisplayViewModel(viewContext: viewContext, initialUserID: userID)
        self.refreshManager = refreshManager
    }
    
    var body: some View {
        NavigationView {
            VStack {
                Text("There are \(viewModel.queueCount) people in the queue for \(viewModel.Currentdestination).")
                    .padding()
                
                Button(action: {
                    showPopup = true
                }) {
                    Text("Join Queue")
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .cornerRadius(10)
                        .padding(.horizontal)
                }
                .padding(.top, 20)
                
                Text("Destination: \(viewModel.Currentdestination). User: \(viewModel.userID)")
                
                NavigationLink(
                    destination: InQueuePage(refreshManager: refreshManager, userID: userID),
                    isActive: $navigateToQueuePage,
                    label: {
                        EmptyView()
                    }
                )
                
                NavigationLink(
                    destination: WelcomePage(refreshManager: refreshManager),
                    isActive: $navigateToWelcomePage,
                    label: {
                        EmptyView()
                    }
                )
            }
            .onAppear {
                viewModel.fetchSelectedDestination()
            }
            .onChange(of: refreshManager.shouldRefresh) { _ in
                viewModel.fetchSelectedDestination()
            }
            .navigationBarTitle("Queue Display", displayMode: .inline)
            .sheet(isPresented: $showPopup) {
                VStack {
                    Text("Payment")
                        .font(.title)
                        .padding(.bottom, 10)
                    
                    Text("1 pound per person, no matter the time spent queuing")
                        .padding(.bottom, 20)
                    
                    HStack {
                        Button(action: {
                            viewModel.deleteUserDocument {
                                showPopup = false
                                navigateToWelcomePage = true
                            }
                        }) {
                            Text("Leave")
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.blue)
                                .cornerRadius(10)
                        }
                        
                        Spacer()
                        
                        Button(action: {
                            showPopup = false
                            navigateToQueuePage = true
                            viewModel.joinQueue()
                        }) {
                            Text("I agree")
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.blue)
                                .cornerRadius(10)
                        }
                    }
                    .padding(.horizontal)
                }
                .padding()
            }
        }
    }
}

        
        
