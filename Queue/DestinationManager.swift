import Combine
import Firebase

class DestinationManager: ObservableObject {
    static let shared = DestinationManager()
    
    private let firestoreDB = Firestore.firestore()
    @Published var destinations: [String] = []
    
    private init() {
        fetchDestinationsFromFirestore()
    }
    
    func searchDestination(_ searchText: String) -> String? {
        return destinations.first { $0.lowercased() == searchText.lowercased() }
    }
    
    func fetchDestinationsFromFirestore() {
        firestoreDB.collection("Destinations").getDocuments { [weak self] querySnapshot, error in
            guard let self = self else { return }
            
            if let error = error {
                print("Error fetching documents: \(error)")
                return
            }
            
            guard let documents = querySnapshot?.documents else {
                print("No documents")
                return
            }
            
            self.destinations = documents.map { $0.documentID } //adding documents to destinations list?
            print("Fetched destinations: \(self.destinations)")
        }
    }
}

