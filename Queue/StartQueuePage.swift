import SwiftUI
import Combine

struct StartQueuePage: View {
    @State public var destinationName: String = ""
    @State public var destinationWebsite: String = ""
    @State private var destinationEntryRate: String = ""
    @State private var destinationNumber: String = ""
    @State public var savedDestinationEntryRate: Int?
    @State public var savedDestinationNumber: Int?
    
    var isDoneEnabled: Bool {
        return !destinationName.isEmpty &&
        !destinationWebsite.isEmpty && destinationWebsite.hasPrefix("https://") &&
        destinationNumber.count == 10 &&
        !destinationEntryRate.isEmpty
    }
    
    var body: some View {
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
            
            TextField("Enter the website url.", text: $destinationWebsite)
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
            
            TextField("Enter how many people to let in at one go.", text: $destinationEntryRate)
                .padding()
                .background(RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.blue, lineWidth: 2)
                    .background(Color.white))
                .foregroundColor(.blue)
                .padding(.bottom)
            
            if isDoneEnabled {
                Button(action: {}) {
                    NavigationLink(destination: ConfirmationPage()) {
                        Text("Done")
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.blue)
                            .cornerRadius(10)
                            .padding(.horizontal)
                    }
                }
            }
        }
    }
}

import SwiftUI

struct ConfirmationPage: View{
    var body: some View{
        Text("🥳")
            .font(.title)
        Text("You've successfully started a new queue!")
        
    }
}


