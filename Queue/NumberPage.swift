import SwiftUI
import Combine

struct NumberPage: View {
    @ObservedObject var refreshManager: RefreshManager 
    @State private var mobileNumber: String = ""
    @State public var savedMobileNumber: Int?
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Please share your mobile number to activate the alert.")
                    .navigationTitle("Contact")
                
                TextField("Enter mobile number", text: $mobileNumber)
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.blue, lineWidth: 2)
                        .background(Color.white))
                    .foregroundColor(.blue)
                
                // Conditional NavigationLink
                if mobileNumber.count == 10 {
                    NavigationLink(destination: TimePage(refreshManager: refreshManager)) {
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
                    .buttonStyle(PlainButtonStyle()) // To remove default button style
                    .onAppear {
                        // Save the mobile number to CoreDataManager
                        CoreDataManager.shared.saveMobileNumber(mobileNumber)
                    }
                }
            }
        }
        .navigationBarHidden(true)
        .onReceive(Just(mobileNumber)) { newValue in
            // Convert the string value to an integer
            if let newMobileNumber = Int(newValue) {
                // Update the savedMobileNumber variable
                self.savedMobileNumber = newMobileNumber
            }
        }
    }
}

