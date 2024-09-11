import SwiftUI

struct HomePage: View {
    @ObservedObject var refreshManager: RefreshManager
    var userID: String
    @State private var searchText: String = ""
    @State private var searchResults: [String] = []
    
    @EnvironmentObject var destinationManager: DestinationManager
    @Environment(\.presentationMode) var presentationMode // Access to the presentation mode to dismiss the view
    
    var body: some View {
        NavigationView {
            VStack {
                Text("🌎 Search for your destination.")
                
                Text("Note: Press enter on your keyboard before searching.")
                    .font(.footnote)
                
                HStack {
                    Spacer()
                    TextField("🔎", text: $searchText, onCommit: {
                        filterDestinations()
                    })
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.blue, lineWidth: 2)
                        .background(Color.white))
                    .foregroundColor(.blue)
                    Spacer()
                }
                Spacer()
                
                NavigationLink(destination: SearchResultsPage(refreshManager: refreshManager, userID: userID, searchResults: searchResults)) {
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
                .disabled(searchText.isEmpty)
                
            }
            Spacer()
        }
        .navigationBarBackButtonHidden(true) // Hides default back button
        .navigationBarItems(leading: Button(action: {
            presentationMode.wrappedValue.dismiss() // Dismiss the current view and go back
        }) {
            HStack {
                Image(systemName: "chevron.left") // Chevron icon for back button
                Text("Back")
            }
            .foregroundColor(.blue)
        })
        .onAppear {
            destinationManager.fetchDestinationsFromFirestore()
        }
    }
    
    private func filterDestinations() {
        if searchText.isEmpty {
            searchResults = destinationManager.destinations
        } else {
            if let result = destinationManager.searchDestination(searchText) {
                searchResults = [result]
            } else {
                searchResults = []
            }
        }
    }
}


import SwiftUI
import FirebaseFirestore

struct SearchResultsPage: View {
    @ObservedObject var refreshManager: RefreshManager
    var userID: String
    var searchResults: [String]
    
    private let db = Firestore.firestore()
    
    var body: some View {
        NavigationView {
            VStack {
                Text("")
                    .navigationTitle("Search Results")
                
                if searchResults.isEmpty {
                    Text("No match was found. Please try again.")
                } else {
                    List(searchResults, id: \.self) { destination in
                        NavigationLink(
                            destination: DestinationPage(refreshManager: refreshManager, destination: destination, userID: userID)
                                .onAppear {
                                    updateSelectedDestination(destination)
                                }
                        ) {
                            Text(destination)
                        }
                    }
                }
            }
        }
        .navigationBarHidden(true)
        .navigationBarBackButtonHidden(true)
    }
    
    private func updateSelectedDestination(_ destination: String) {
        let userRef = db.collection("users").document(userID)
        
        userRef.updateData([
            "SelectedDestination": destination
        ]) { error in
            if let error = error {
                print("Error updating document: \(error)")
            } else {
                print("Document successfully updated")
            }
        }
    }
}
