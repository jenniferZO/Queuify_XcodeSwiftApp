//
//  ContentView.swift
//  Queue
//
//  Created by Zhao, Jennifer (OXF) Student on 26/06/2024.
//

import SwiftUI

struct ContentView: View {
    @ObservedObject var refreshManager: RefreshManager
    @State private var queuePosition = CoreDataManager.shared.getQueueCount()
    @State private var peopleJoining = CoreDataManager.shared.getPeopleJoining() ?? 0
    var body: some View {
        NavigationView {
            VStack {
                Spacer()
                
                Text("👋 Welcome!") // Waving hand emoji with Welcome text
                Text("You are in position \(queuePosition) of the line.")
                
                Spacer()
                
                NavigationLink(destination: HomePage(refreshManager: refreshManager)) {
                    HStack {
                        Spacer()
                        Text("Join a Queue")
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.blue)
                            .cornerRadius(10)
                            .padding(.horizontal)
                    }
                }
                
                NavigationLink(destination: StartQueuePage()) {
                    HStack {
                        Spacer()
                        Text("Start a Queue")
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.blue)
                            .cornerRadius(10)
                            .padding(.horizontal)
                    }
                }
                
                Spacer()
            }
            .onReceive(refreshManager.$shouldRefresh) { _ in
                // Update queuePosition1 when returning from InQueuePage
                queuePosition = CoreDataManager.shared.getQueueCount()
            }
        }
        .navigationBarHidden(true)
    }
}


