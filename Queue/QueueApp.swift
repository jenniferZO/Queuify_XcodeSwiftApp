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

@main
struct MyApp: App {
    // register app delegate for Firebase setup
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

    @StateObject private var refreshManager = RefreshManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView(refreshManager: refreshManager)
        }
    }
}
class AppDelegate: UIResponder, UIApplicationDelegate {

  var window: UIWindow?

  func application(_ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions:
                   [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    FirebaseApp.configure()

    return true
  }
}

