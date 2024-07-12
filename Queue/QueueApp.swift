import SwiftUI
import UIKit
import FirebaseCore
import CoreData

class RefreshManager: ObservableObject {
    @Published var shouldRefresh = false
    
    func triggerRefresh() {
        shouldRefresh.toggle()
    }
}

class AppDelegate: NSObject, UIApplicationDelegate {
    var window: UIWindow?
    
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "CoreData") // Replace with your data model name
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()
    
    func saveContext() {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }
    
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()
        return true
    }
}

@main
struct YourApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

    @StateObject private var refreshManager = RefreshManager()
    @StateObject private var destinationManager = DestinationManager.shared // Instantiate DestinationManager
    
    var body: some Scene {
        WindowGroup {
            WelcomePage(refreshManager: refreshManager)
                .environment(\.managedObjectContext, delegate.persistentContainer.viewContext)
                .environmentObject(destinationManager) // Inject DestinationManager as environment object
        }
    }
}
