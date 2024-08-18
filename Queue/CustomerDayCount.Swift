import Foundation
import FirebaseFirestore

class CustomerDayCountManager {
    static let shared = CustomerDayCountManager()
    private let userDefaults = UserDefaults.standard
    private let customerDayCountKey = "CustomerDayCount"
    private let lastResetDateKey = "LastResetDate"
    
    private let destinationDocumentID = "yourDestinationDocumentID" // Replace with actual document ID
    
    init() {
        // Ensure the count is checked and reset if needed on initialization
        checkAndResetIfNeeded()
        
        // Schedule a background task to reset the count every 24 hours
        scheduleBackgroundResetTask()
    }

    var customerDayCount: Int {
        get {
            checkAndResetIfNeeded()
            return userDefaults.integer(forKey: customerDayCountKey)
        }
        set {
            userDefaults.set(newValue, forKey: customerDayCountKey)
            updateCustomerDayCountInFirestore(newValue)
        }
    }

    private func checkAndResetIfNeeded() {
        let now = Date()
        if let lastResetDate = userDefaults.object(forKey: lastResetDateKey) as? Date {
            if now.timeIntervalSince(lastResetDate) >= 86400 { // 86400 seconds = 24 hours
                resetCustomerDayCount()
            }
        } else {
            // If there is no last reset date, set it to now
            userDefaults.set(now, forKey: lastResetDateKey)
        }
    }

    private func resetCustomerDayCount() {
        userDefaults.set(0, forKey: customerDayCountKey)
        userDefaults.set(Date(), forKey: lastResetDateKey)
        updateCustomerDayCountInFirestore(0)
    }
    
    private func scheduleBackgroundResetTask() {
        // Schedule a task to reset customerDayCount every 24 hours
        Timer.scheduledTimer(withTimeInterval: 86400, repeats: true) { _ in
            self.resetCustomerDayCount()
        }
    }
    
    private func updateCustomerDayCountInFirestore(_ newValue: Int) {
        let db = Firestore.firestore()
        let destinationRef = db.collection("Destinations").document(destinationDocumentID) //maybe change to destination?
        
        destinationRef.updateData(["CustomerDayCount": newValue]) { error in
            if let error = error {
                print("Error updating CustomerDayCount in Firestore: \(error.localizedDescription)")
            } else {
                print("CustomerDayCount updated successfully in Firestore.")
            }
        }
    }
}
