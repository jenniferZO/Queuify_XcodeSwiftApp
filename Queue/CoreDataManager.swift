import CoreData

class CoreDataManager {
    static let shared = CoreDataManager()
    
    private var _destinations: [String] = []
    private var userComments: [String] = [] // Array to store user comments
    private var peopleJoining: Int = 0
    private var mobileNumber: String?
    private var selectedTime: String?
    private var selectedDate: String?
    public var queueCount: Int = 0
    
    var destinations: [String] {
        return _destinations
    }
    
    func saveDestination(_ destinationName: String) {
        _destinations.append(destinationName)
    }
    
    func searchDestinations(for searchText: String) -> [String] {
        return _destinations.filter { $0.lowercased().contains(searchText.lowercased()) }
    }
    
    func savePeopleJoining(_ count:Int){
        peopleJoining = count
    }
    
    func getPeopleJoining()-> Int? {
        return peopleJoining
    }
    
    func saveMobileNumber(_ number: String) {
        mobileNumber = number
    }
    
    func getMobileNumber() -> String? {
        return mobileNumber
    }
    
    func saveSelectedTime(_ time: String) {
        selectedTime = time
    }
    
    func getSelectedTime() -> String? {
        return selectedTime
    }
    
    func saveSelectedDate(_ date: String) {
        selectedDate = date
    }
    
    func getSelectedDate() -> String? {
        return selectedDate
    }
    
    func saveQueueCount(_ count: Int) {
        queueCount = count
    }
    
    func getQueueCount() -> Int {
        return queueCount
    }
    
    // Save user comment
    func saveUserComment(_ comment: String) {
        userComments.append(comment)
    }
    
    // Retrieve all user comments
    func getAllUserComments() -> [String] {
        return userComments
    }
}
