import SwiftUI
import FirebaseFirestore

struct User {
    var UserID: String
    var SelectedDestination: String
    var PeopleJoining: Int
}

struct WelcomePage: View {
    @ObservedObject var refreshManager: RefreshManager
    @State private var user: User?
    @State private var navigateToHomePage = false
    @State private var navigateToStartPage = false
    @State private var showConsentPopup = false
    @State private var consentGiven = UserDefaults.standard.bool(forKey: "consentGiven")
    @State private var consentAction: (() -> Void)?

    private let coreDataManager = CoreDataManager.shared
    private let firestore = Firestore.firestore()

    // Public initializer
    init(refreshManager: RefreshManager) {
        self.refreshManager = refreshManager
    }

    var body: some View {
        NavigationView {
            VStack {
                Spacer()
                Text("👋 Welcome!") // Waving hand emoji with Welcome text
                Spacer()

                JoinQueueButton(title: "Join a Queue") {
                    if !consentGiven {
                        consentAction = {
                            generateAndSaveUser {
                                navigateToHomePage = true
                            }
                        }
                        showConsentPopup = true
                    } else {
                        generateAndSaveUser {
                            navigateToHomePage = true
                        }
                    }
                }

                JoinQueueButton(title: "Start a Queue") {
                    if !consentGiven {
                        consentAction = {
                            generateAndSaveUser {
                                navigateToStartPage = true
                            }
                        }
                        showConsentPopup = true
                    } else {
                        generateAndSaveUser {
                            navigateToStartPage = true
                        }
                    }
                }

                Spacer()
            }
            .onAppear {
                if let userID = coreDataManager.getUserID() {
                    self.user = User(UserID: userID, SelectedDestination: "", PeopleJoining: 0)
                }
            }
            .onReceive(refreshManager.$shouldRefresh) { _ in
                // Update any necessary state here when refreshing
            }
            .navigationBarHidden(true)
            .background(
                NavigationLink(destination: HomePage(refreshManager: refreshManager, userID: user?.UserID ?? ""), isActive: $navigateToHomePage) {
                    EmptyView()
                }
            )
            .background(
                NavigationLink(destination: StartQueuePage(refreshManager: refreshManager), isActive: $navigateToStartPage) {
                    EmptyView()
                }
            )
            .sheet(isPresented: $showConsentPopup) {
                ConsentPopup(showPopup: $showConsentPopup, consentGiven: $consentGiven)
            }
            .onChange(of: consentGiven) { newValue in
                if newValue {
                    consentAction?()
                    consentGiven = false // Reset consent for future actions
                }
            }
        }
        .navigationBarBackButtonHidden(true)
    }

    // Function to generate a unique 8-digit user ID
    func generateUniqueUserID() -> String {
        let userID = String(format: "%08d", Int.random(in: 0..<100000000))
        return userID
    }

    func generateAndSaveUser(completion: @escaping () -> Void) {
        let userID = generateUniqueUserID()
        coreDataManager.saveUserIDToCoreData(userID: userID) // Save userID to Core Data
        
        let newUser = User(UserID: userID, SelectedDestination: "", PeopleJoining: 0)
        self.user = newUser
        
        // Save userID to Firestore
        let userRef = firestore.collection("users").document(userID)
        userRef.setData([
            "UserID": userID,
            "SelectedDestination": newUser.SelectedDestination,
            "PeopleJoining": newUser.PeopleJoining
        ]) { error in
            if let error = error {
                print("Error adding user to Firestore: \(error)")
            } else {
                print("User successfully added to Firestore")
            }
            completion()
        }
    }

    // Custom Button View for JoinQueueButton
    struct JoinQueueButton: View {
        var title: String
        var backgroundColor: Color = .blue
        var action: () -> Void

        var body: some View {
            Button(action: action) {
                HStack {
                    Spacer()
                    Text(title)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(backgroundColor)
                        .cornerRadius(10)
                        .padding(.horizontal)
                }
            }
        }
    }
}


struct ConsentPopup: View {
    @Binding var showPopup: Bool
    @Binding var consentGiven: Bool

    @State private var isFirstCheckboxChecked = false
    @State private var isSecondCheckboxChecked = false
    @State private var showAlert = false

    var body: some View {
        VStack {
            Text("Consent Required")
                .font(.title)
                .padding()

            Toggle(isOn: $isFirstCheckboxChecked) {
                Text("I agree to the Terms and Conditions")
            }
            .padding()

            Toggle(isOn: $isSecondCheckboxChecked) {
                HStack {
                    Text("I agree to the ")
                    Link("Privacy Policy", destination: URL(string: "https://docs.google.com/document/d/1nAleWu430pfYG6nF4D4oJKwaCh09Vu3Pd3AueOW8zi0/edit#heading=h.dq81c8ha62qw")!)
                }
            }
            .padding()

            HStack {
                Button(action: {
                    showPopup = false
                }) {
                    Text("Cancel")
                }
                .padding()

                Spacer()

                Button(action: {
                    if isFirstCheckboxChecked && isSecondCheckboxChecked {
                        consentGiven = true
                        showPopup = false
                        UserDefaults.standard.set(true, forKey: "consentGiven")
                    } else {
                        showAlert = true // Show alert if not both checkboxes are checked
                    }
                }) {
                    Text("Continue")
                }
                .padding()
            }
        }
        .padding()
        .alert(isPresented: $showAlert) {
            Alert(title: Text("Missing Consent"), message: Text("Please select both checkboxes to continue."), dismissButton: .default(Text("OK")))
        }
    }
}

