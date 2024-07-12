import SwiftUI
import FirebaseFirestore
import CoreData

class QueueDisplayViewModel: ObservableObject {
    @Published var db: Firestore = Firestore.firestore()
    @Published var queueCount: Int = 0
    @Published var destination: String = ""
    @Published var user: User? // Define a property to hold the user object
    
    private var viewContext: NSManagedObjectContext
    
    init(viewContext: NSManagedObjectContext) {
        self.viewContext = viewContext
        fetchSelectedDestination()
    }
    
    func fetchQueueCount() {
        guard !destination.isEmpty else {
            print("Destination is empty")
            return
        }
        
        let destinationRef = db.collection("destinations").document(destination).collection("queueList")
        
        destinationRef.addSnapshotListener { snapshot, error in
            guard let documents = snapshot?.documents else {
                print("Error fetching queue list: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            
            var totalPeopleInQueue = 0
            
            for document in documents {
                if let peopleJoining = document.data()["peopleJoining"] as? Int {
                    totalPeopleInQueue += peopleJoining
                }
            }
            
            DispatchQueue.main.async {
                self.queueCount = totalPeopleInQueue
            }
        }
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
            print("User ID is nil")
            return
        }
        
        let userRef = db.collection("users").document(userID)
        
        userRef.getDocument { [weak self] snapshot, error in
            guard let self = self else { return }
            
            if let error = error {
                print("Error fetching user document: \(error.localizedDescription)")
                return
            }
            
            guard let userData = snapshot?.data() else {
                print("User document not found")
                return
            }
            
            if let selectedDestination = userData["destination"] as? String {
                DispatchQueue.main.async {
                    self.destination = selectedDestination
                    self.fetchQueueCount()
                }
            } else {
                print("Destination field not found in user document")
            }
        }
    }
    
    func joinQueue() {
        guard let userID = getUserID(), !destination.isEmpty else {
            print("User ID or Destination is nil")
            return
        }
        
        let userRef = db.collection("users").document(userID)
        
        userRef.getDocument { [weak self] userDocument, error in
            guard let self = self else { return }
            
            if let error = error {
                print("Error fetching user document: \(error.localizedDescription)")
                return
            }
            
            guard let userData = userDocument?.data() else {
                print("User document not found")
                return
            }
            
            if let userDestination = userData["destination"] as? String {
                // Creating a reference to the destination document
                let destinationRef = self.db.collection("Destinations").document(userDestination)
                
                // Creating a reference to the QueueList collection under the destination document
                let destinationQueueRef = destinationRef.collection("QueueList").document(userID)
                
                // Adding a reference to the user's document in the QueueList
                destinationQueueRef.setData([
                    "userRef": userRef
                ]) { error in
                    if let error = error {
                        print("Error joining queue: \(error.localizedDescription)")
                    } else {
                        print("User \(userID) joined the queue successfully.")
                        self.fetchQueueCount()
                    }
                }
            } else {
                print("Destination field not found in user document")
            }
        }
    }
}
struct QueueDisplay: View {
    @Environment(\.managedObjectContext) private var viewContext
    @ObservedObject var viewModel: QueueDisplayViewModel
    var refreshManager: RefreshManager
    
    @State private var navigateToQueuePage = false  // State variable for navigation
    
    init(viewContext: NSManagedObjectContext, refreshManager: RefreshManager) {
        self.viewModel = QueueDisplayViewModel(viewContext: viewContext)
        self.refreshManager = refreshManager
    }
    
    var body: some View {
        NavigationView {
            VStack {
                Text("There are \(viewModel.queueCount) people in the queue for \(viewModel.destination).")
                    .padding()
                
                if let user = viewModel.user {
                    Button(action: {
                        viewModel.joinQueue()
                        navigateToQueuePage = true  // Activate navigation
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
                    .background(
                        NavigationLink(
                            destination: InQueuePage(refreshManager: refreshManager, user: user),
                            isActive: $navigateToQueuePage,
                            label: {
                                EmptyView()
                            })
                    )
                } else {
                    Text("Loading user data...")
                        .padding()
                }
            }
            .onAppear {
                viewModel.fetchSelectedDestination()
            }
            .onChange(of: refreshManager.shouldRefresh) { _ in
                viewModel.fetchSelectedDestination()
            }
            .navigationBarTitle("Queue Display", displayMode: .inline)
        }
    }
}
