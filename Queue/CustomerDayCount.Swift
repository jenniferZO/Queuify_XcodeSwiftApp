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
        
        
        // Schedule a background task to reset the count at the next 6 PM
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
    
    // Function to set initial customerDayCount for a new destination document
     func setInitialCustomerDayCount(for documentID: String) {
         let db = Firestore.firestore()
         let destinationRef = db.collection("Destinations").document(documentID)
         
         // Check if the document exists and set customerDayCount to 0 if it's new
         destinationRef.getDocument { document, error in
             if let document = document, !document.exists {
                 destinationRef.setData(["CustomerDayCount": 0], merge: true) { error in
                     if let error = error {
                         print("Error setting initial CustomerDayCount: \(error.localizedDescription)")
                     } else {
                         print("CustomerDayCount initialized to 0 for new destination.")
                     }
                 }
             }
         }
     }

    private func checkAndResetIfNeeded() {
        let now = Date()
        let calendar = Calendar.current
        
        // Get the next 6 PM London time
        var components = calendar.dateComponents([.year, .month, .day], from: now)
        components.hour = 18
        components.minute = 0
        components.second = 0
        components.timeZone = TimeZone(identifier: "Europe/London") // Set the time zone to London
        
        guard let today6PM = calendar.date(from: components) else {
            return
        }
        
        // If the current time is past 6 PM, calculate the next day's 6 PM
        let nextResetDate: Date
        if now >= today6PM {
            nextResetDate = calendar.date(byAdding: .day, value: 1, to: today6PM)!
        } else {
            nextResetDate = today6PM
        }

        if let lastResetDate = userDefaults.object(forKey: lastResetDateKey) as? Date {
            // If the last reset was before the most recent 6 PM, reset the count
            if lastResetDate < today6PM && now >= today6PM {
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
        let calendar = Calendar.current
        let now = Date()
        
        // Calculate the next 6 PM London time
        var components = calendar.dateComponents([.year, .month, .day], from: now)
        components.hour = 18
        components.minute = 0
        components.second = 0
        components.timeZone = TimeZone(identifier: "Europe/London") // Set the time zone to London
        
        guard let today6PM = calendar.date(from: components) else {
            return
        }
        
        let nextResetDate: Date
        if now >= today6PM {
            nextResetDate = calendar.date(byAdding: .day, value: 1, to: today6PM)!
        } else {
            nextResetDate = today6PM
        }
        
        let timeInterval = nextResetDate.timeIntervalSince(now)
        
        Timer.scheduledTimer(withTimeInterval: timeInterval, repeats: false) { _ in
            self.resetCustomerDayCount()
            
            // Reschedule the timer for the next 6 PM after resetting
            self.scheduleBackgroundResetTask()
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

