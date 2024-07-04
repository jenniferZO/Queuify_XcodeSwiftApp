import Foundation

struct DestinationManager {
    static let shared = DestinationManager()
    
    // List of destination variables
    let destinations: [String] = ["Shop", "Museum", "Attraction"]
    
    // Function to search for a destination
    func searchDestination(_ searchText: String) -> String? {
        for destination in destinations {
            if destination.lowercased() == searchText.lowercased() {
                return destination
            }
        }
        return nil // Destination not found
    }
}

