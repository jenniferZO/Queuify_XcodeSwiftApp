import SwiftUI

struct HomePage: View {
    @ObservedObject var refreshManager: RefreshManager
    @State private var searchText: String = ""
    @State private var searchResults: [String] = []
    
    // Function to filter destinations based on search text
    public func filterDestinations() {
        if searchText.isEmpty {
            // If search text is empty, show all destinations
            searchResults = DestinationManager.shared.destinations
        } else {
            // Search destinations using DestinationManager
            if let result = DestinationManager.shared.searchDestination(searchText) {
                searchResults = [result]
            } else {
                searchResults = []
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack {
                Text("🌎 Select your destination.")
                
                HStack {
                    Spacer()
                    TextField("🔎", text: $searchText, onCommit: {
                        filterDestinations() // Filter destinations when user presses return/Enter
                    })
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.blue, lineWidth: 2)
                        .background(Color.white))
                    .foregroundColor(.blue)
                    Spacer()
                }
                Spacer()
                
                NavigationLink(destination: SearchResultsPage(refreshManager: refreshManager, searchResults: searchResults)) {
                    HStack {
                        Spacer()
                        Text("Search")
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.blue)
                            .cornerRadius(10)
                            .padding(.horizontal)
                    }
                }
                .disabled(searchText.isEmpty) // Disable the search button if search text is empty
                .navigationBarBackButtonHidden(true) // Hide navigation back button
            }
            Spacer()
        }
    }
}

struct SearchResultsPage: View {
    @ObservedObject var refreshManager: RefreshManager 
    var searchResults: [String]
    
    var body: some View {
        NavigationView {
            VStack {
                Text("")
                    .navigationTitle("Search Results")
                
                if searchResults.isEmpty {
                    Text("No match was found. Please try again.")
                } else {
                    List(searchResults, id: \.self) { destination in
                        NavigationLink(destination: DestinationPage(refreshManager: refreshManager, destination: destination)) {
                            Text(destination)
                        }
                    }
                }
            }
        }
        .navigationBarHidden(true)
    }
}

