import SwiftUI
import Firebase

struct StartQueuePage: View {
    @ObservedObject var refreshManager: RefreshManager
    @State private var destinationName: String = ""
    @State private var destinationNumber: String = ""
    @State private var destinationAddress: String = ""
    @State private var destinationEmail: String = ""
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var agreementChecked = false
    @State private var navigateToWelcomePage = false
    
    var customerDayCount: Int {
        CustomerDayCountManager.shared.customerDayCount
    }
    
    var isDoneEnabled: Bool {
        return !destinationName.isEmpty && destinationNumber.count == 10 && agreementChecked
    }
    
    var body: some View {
        NavigationView {
            VStack {
                Text("")
                    .navigationTitle("Start a Queue")
                
                TextField("Enter the name of destination", text: $destinationName)
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.blue, lineWidth: 2)
                        .background(Color.white))
                    .foregroundColor(.blue)
                    .padding(.bottom)
                
                TextField("Enter the email address", text: $destinationEmail)
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.blue, lineWidth: 2)
                        .background(Color.white))
                    .foregroundColor(.blue)
                    .padding(.bottom)
                
                TextField("Enter the main mobile number.", text: $destinationNumber)
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.blue, lineWidth: 2)
                        .background(Color.white))
                    .foregroundColor(.blue)
                    .padding(.bottom)
                
                TextField("Enter the address", text: $destinationAddress)
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.blue, lineWidth: 2)
                        .background(Color.white))
                    .foregroundColor(.blue)
                    .padding(.bottom)
                
                Toggle(isOn: $agreementChecked) {
                    HStack {
                        Text("I agree to the ")
                        Link("terms and conditions", destination: URL(string: "https://docs.google.com/document/d/10fCPV_uUKXMKfKeovYvJ7_hpjN-vSlcuhyRFCpAwc3U/edit")!)
                    }
                }
                .padding()
                
                if isDoneEnabled {
                    Button(action: {
                        self.checkAndAddDestination()
                    }) {
                        Text("Done")
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.blue)
                            .cornerRadius(10)
                            .padding(.horizontal)
                    }
                }
                
                // NavigationLink for WelcomePage
                NavigationLink(
                    destination: WelcomePage(refreshManager: refreshManager),
                    isActive: $navigateToWelcomePage,
                    label: { EmptyView() }
                )
            }
            .alert(isPresented: $showingAlert) {
                Alert(
                    title: Text(alertMessage),
                    dismissButton: .default(Text("OK")) {
                        if alertMessage == "Congratulations! You have started a new queue" {
                            // Trigger navigation on "OK" button press
                            navigateToWelcomePage = true
                        }
                    }
                )
            }
        }
    }
    
    private func checkAndAddDestination() {
        let db = Firestore.firestore()
        let destinationRef = db.collection("Destinations").document(destinationName)
        
        destinationRef.getDocument { document, error in
            if let document = document, document.exists {
                self.alertMessage = "There is an already existing destination. Please change the name."
                self.showingAlert = true
            } else {
                let destinationContact = Int(destinationNumber) ?? 0
                let destinationData: [String: Any] = [
                    "DestinationContact": destinationContact,
                    "DestinationEmail": destinationEmail,
                    "DestinationName": destinationName,
                    "DestinationAddress": destinationAddress,
                    "CustomerDayCount": 0,
                    "QueueList": []
                ]
                
                destinationRef.setData(destinationData) { error in
                    if let error = error {
                        self.alertMessage = "Error: \(error.localizedDescription)"
                    } else {
                        // Call the method to set initial CustomerDayCount
                        CustomerDayCountManager.shared.setInitialCustomerDayCount(for: destinationName)
                        
                        self.alertMessage = "Congratulations! You have started a new queue"
                    }
                    self.showingAlert = true
                }
            }
        }
    }
}
