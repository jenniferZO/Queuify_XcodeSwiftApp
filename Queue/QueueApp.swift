//
//  QueueApp.swift
//  Queue
//
//  Created by Zhao, Jennifer (OXF) Student on 26/06/2024.
//



import SwiftUI
import UIKit
import FirebaseCore


class RefreshManager: ObservableObject {
    @Published var shouldRefresh = false
    
    func triggerRefresh() {
        shouldRefresh.toggle()
    }
}
class AppDelegate: NSObject, UIApplicationDelegate {
  func application(_ application: UIApplication,
                   didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
    FirebaseApp.configure()

    return true
  }
}
@main

struct YourApp: App {
    // register app delegate for Firebase setup
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

    @StateObject private var refreshManager = RefreshManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView(refreshManager: refreshManager)
        }
    }
}



