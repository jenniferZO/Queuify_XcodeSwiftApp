import SwiftUI
import Firebase
import FirebaseFirestore

struct DestinationPage: View {
    @ObservedObject var refreshManager: RefreshManager
    @State private var isIndividualSelected = false
    @State private var isGroupSelected = false
    @State private var numberOfPeopleInGroup = 0
    var destination: String
    var userID: String
    
    var body: some View {
        NavigationView {
            VStack {
                Text(destination)
                    .font(.title)
                    .padding()
                    .navigationBarTitle("My Queue")
                    .navigationBarBackButtonHidden(true)
        
                
                HStack(spacing: 10) {
                    Button(action: {
                        isIndividualSelected = true
                        isGroupSelected = false
                    }) {
                        Text("Individual")
                            .foregroundColor(isIndividualSelected ? .white : .blue)
                            .padding()
                            .background(isIndividualSelected ? Color.blue : Color.white)
                            .cornerRadius(10)
                    }
                    
                    Button(action: {
                        isIndividualSelected = false
                        isGroupSelected = true
                    }) {
                        Text("Group")
                            .foregroundColor(isGroupSelected ? .white : .blue)
                            .padding()
                            .background(isGroupSelected ? Color.blue : Color.white)
                            .cornerRadius(10)
                    }
                }
                .padding()
                
                if isGroupSelected {
                    HStack(spacing: 10) {
                        Button(action: {
                            if numberOfPeopleInGroup > 0 {
                                numberOfPeopleInGroup -= 1
                            }
                        }) {
                            Image(systemName: "minus")
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                        
                        TextField("Number of people", value: $numberOfPeopleInGroup, formatter: NumberFormatter())
                            .padding()
                            .background(Color.white)
                            .foregroundColor(.blue)
                            .multilineTextAlignment(.center)
                            .keyboardType(.numberPad)
                            .frame(width: 100)
                        
                        Button(action: {
                            numberOfPeopleInGroup += 1
                        }) {
                            Image(systemName: "plus")
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                    }
                    .padding()
                }
                
                // Conditional NavigationLink
                if isDestinationSelected() {
                    NavigationLink(destination: QueueDisplay(viewContext: CoreDataManager.shared.persistentContainer.viewContext, refreshManager: refreshManager, userID: userID)) {
                        HStack {
                            Spacer()
                            Text("Next")
                                .foregroundColor(.white)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.blue)
                                .cornerRadius(10)
                                .padding(.horizontal)
                        }
                    }
                    .disabled(!isDestinationSelected()) // Disable navigation if no destination is selected
                    .onDisappear {
                        // Save the number of people joining the queue and queue count when the view disappears
                        savePeopleJoiningAndQueueCount()
                        updateCustomerDayCount(peopleJoining: isIndividualSelected ? 1 : numberOfPeopleInGroup)
                    }
                }
            }
        }
        .navigationBarHidden(true)
    }
    
    // Function to check if a destination is selected
    private func isDestinationSelected() -> Bool {
        // Check if individual or group is selected
        if isIndividualSelected || isGroupSelected {
            // If group is selected, check if number of people is greater than 0
            if isGroupSelected && numberOfPeopleInGroup <= 0 {
                return false
            }
            return true
        }
        return false
    }
    
    // Function to save the number of people joining the queue and increment queue count to Firestore
    private func savePeopleJoiningAndQueueCount() {
        let peopleJoining = isIndividualSelected ? 1 : numberOfPeopleInGroup
        // Update peopleJoining in Firestore
        updatePeopleJoiningInFirestore(peopleJoining)
    }
    
    // Function to update peopleJoining field under the user document in Firestore
    private func updatePeopleJoiningInFirestore(_ peopleJoining: Int) {
        let db = Firestore.firestore()
        let userRef = db.collection("users").document(userID)
        
        userRef.updateData(["PeopleJoining": peopleJoining]) { error in
            if let error = error {
                print("Error updating peopleJoining in Firestore: \(error.localizedDescription)")
            } else {
                print("People joining updated successfully for user \(userID).")
            }
        }
    }
    
    private func updateCustomerDayCount(peopleJoining: Int) {
        let db = Firestore.firestore()
        let destinationRef = db.collection("Destinations").document(destination)
        
        destinationRef.updateData([
            "CustomerDayCount": FieldValue.increment(Int64(peopleJoining))
        ]) { error in
            if let error = error {
                print("Error updating CustomerDayCount in Firestore: \(error.localizedDescription)")
            } else {
                print("CustomerDayCount updated successfully for destination \(destination).")
            }
        }
        
        // Update the local count managed by CustomerDayCountManager
        CustomerDayCountManager.shared.customerDayCount += peopleJoining
    }
}
    
