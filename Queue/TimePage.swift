import SwiftUI

struct TimePage: View {
    @ObservedObject var refreshManager : RefreshManager
    @State public var isTodaySelected = false
    @State private var selectedDate: Date = Date()
    @State private var selectedHour: String?
    @State private var selectedMinute: String?
    @State private var selectedPeriod: String?
    @State private var navigateToInQueue = false 
 
    let hours = Array(stride(from: 1, through: 12, by: 1)).map { String($0) }
    let minutes = ["00", "30"]
    let periods = ["AM", "PM"]
    
    // Computed property to determine the queue count
    private var queueCount: Int {
        // Check if all necessary components for time selection are present
        guard let selectedHour = selectedHour,
              let selectedMinute = selectedMinute,
              let selectedPeriod = selectedPeriod else {
            // Return default queue count if any of the components are nil
            return CoreDataManager.shared.getQueueCount() + 1
        }
        
        // Retrieve the number of people joining from CoreDataManager
        if let peopleJoining = CoreDataManager.shared.getPeopleJoining() {
            if peopleJoining > 0 {
                // Increment queueCount by the number of people joining
                return CoreDataManager.shared.getQueueCount() + peopleJoining
            } else {
                // Increment queueCount by 1 if no people joining or invalid selection
                return CoreDataManager.shared.getQueueCount() + 1
            }
        } else {
            // Handle the case if getPeopleJoining() returns nil
            // Default to incrementing queueCount by 1
            return CoreDataManager.shared.getQueueCount() + 1
        }
    }

    
    var body: some View {
        NavigationView {
            VStack {
                Text("Select a time to queue.")
                
                HStack() {
                    Button(action: {
                        isTodaySelected = true
                    }) {
                        Text("Today")
                            .foregroundColor(isTodaySelected ? .white : .blue)
                            .padding()
                            .background(isTodaySelected ? Color.blue : Color.white)
                            .cornerRadius(10)
                    }
                    
                }
                
                HStack(spacing: 10) {
                    // Button for selecting hour
                    ScrollView(.vertical) {
                        VStack(spacing: 10) {
                            ForEach(hours, id: \.self) { hour in
                                Button(action: {
                                    selectedHour = hour
                                }) {
                                    Text(hour)
                                        .frame(width: 80, height: 150) // Set fixed height for one value
                                        .padding()
                                        .background(selectedHour == hour ? Color.blue : Color.white)
                                        .foregroundColor(selectedHour == hour ? .white : .blue)
                                        .cornerRadius(10)
                                }
                            }
                        }
                    }
                    
                    // Button for selecting minutes
                    ScrollView(.vertical) {
                        VStack(spacing: 10) {
                            ForEach(minutes, id: \.self) { minute in
                                Button(action: {
                                    selectedMinute = minute
                                }) {
                                    Text(minute)
                                        .frame(width: 80, height: 150) // Set fixed height for one value
                                        .padding()
                                        .background(selectedMinute == minute ? Color.blue : Color.white)
                                        .foregroundColor(selectedMinute == minute ? .white : .blue)
                                        .cornerRadius(10)
                                }
                            }
                        }
                    }
                    
                    // Button for selecting period
                    ScrollView(.vertical) {
                        VStack(spacing: 10) {
                            ForEach(periods, id: \.self) { period in
                                Button(action: {
                                    selectedPeriod = period
                                }) {
                                    Text(period)
                                        .frame(width: 60, height: 150) // Set fixed height for one value
                                        .padding()
                                        .background(selectedPeriod == period ? Color.blue : Color.white)
                                        .foregroundColor(selectedPeriod == period ? .white : .blue)
                                        .cornerRadius(10)
                                }
                            }
                        }
                    }
                }
                
                // Conditional binding for NavigationLink
                if let selectedHour = selectedHour,
                   let selectedMinute = selectedMinute,
                   let selectedPeriod = selectedPeriod {
                    // Join the Queue Button
                    Button(action: {
                        // Save the selected time
                        CoreDataManager.shared.saveSelectedTime(selectedHour + ":" + selectedMinute + " " + selectedPeriod)
                        
                        // Calculate the updated queue count only when the user confirms
                        let peopleJoining = CoreDataManager.shared.getPeopleJoining() ?? 0
                        let updatedQueueCount = queueCount + peopleJoining
                        
                        // Save the updated queue count
                        CoreDataManager.shared.saveQueueCount(updatedQueueCount)
                        
                        // Navigate to InQueuePage
                        navigateToInQueue = true
                    }) {
                        NavigationLink(destination: InQueuePage(refreshManager: refreshManager), isActive: $navigateToInQueue) {
                            HStack {
                                Text("Join the Queue")
                                    .foregroundColor(.white)
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .background(Color.blue)
                                    .cornerRadius(10)
                                    .padding(.horizontal)
                            }
                        }
                        .buttonStyle(PlainButtonStyle()) // To remove default button style
                        .onTapGesture {
                            refreshManager.triggerRefresh() // Trigger refresh when the button is tapped
                        }
                    }
                }

            }
            .navigationBarHidden(true)
        }
    }
}

