import SwiftUI

struct DestinationPage: View {
    @ObservedObject var refreshManager: RefreshManager
    @State private var isIndividualSelected = false
    @State private var isGroupSelected = false
    @State private var numberOfPeopleInGroup = 0
    var destination: String // Change the destination type to String
    
    var body: some View {
        NavigationView {
            VStack {
                Text(destination)
                    .font(.title)
                    .padding()
                    .navigationBarTitle("My Queue")
                
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
                    NavigationLink(destination: NumberPage(refreshManager: refreshManager)) {
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
                    }
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            saveDestinationToCoreData() // Save the selected destination to Core Data when the view appears
        }
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
    
    // Function to save the selected destination to Core Data
    private func saveDestinationToCoreData() {
        CoreDataManager.shared.saveDestination(destination)
    }
    
    // Function to save the number of people joining the queue and increment queue count to Core Data
    private func savePeopleJoiningAndQueueCount() {
        // Save the number of people joining the queue
        CoreDataManager.shared.savePeopleJoining(isIndividualSelected ? 1 : numberOfPeopleInGroup)
        
        // Increment the queue count
        var queueCount = CoreDataManager.shared.getQueueCount()
        queueCount += (isIndividualSelected ? 1 : numberOfPeopleInGroup)
        CoreDataManager.shared.saveQueueCount(queueCount)
    }
}

