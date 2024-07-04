import SwiftUI

struct InQueuePage: View {
    @ObservedObject var refreshManager: RefreshManager
    @State private var queuePosition = CoreDataManager.shared.getQueueCount()
    @State private var peopleJoining = CoreDataManager.shared.getPeopleJoining() ?? 0
    @State private var showingConfirmation = false // State for confirmation popup
    @State private var showingReviewPopup = false // State for review popup
    @State private var userComment: String = ""
    @State private var navigateToContentView = false // State for navigation
    @State private var rating: Int = 0 // State for rating in the review popup
    @State private var showingCommentsPopup = false // State for showing comments popup
    
    var body: some View {
        NavigationView {
            ZStack(alignment: .bottomTrailing) {
                VStack {
                    Text("You are in position \(queuePosition) of the line.")
                        .padding()
                    
                    Text("Please click the refresh button below to see your current position.")
                        .font(.footnote)
                    
                    Spacer()
                    
                    Button(action: {
                        // Show confirmation popup
                        showingConfirmation = true
                    }) {
                        HStack {
                            Text("Leave the Queue")
                                .foregroundColor(.white)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.blue)
                                .cornerRadius(10)
                                .padding(.horizontal)
                        }
                    }
                    .buttonStyle(PlainButtonStyle()) // To remove default button style
                    .alert(isPresented: $showingConfirmation) {
                        Alert(
                            title: Text("Are you sure you want to leave the queue?"),
                            primaryButton: .default(Text("Yes")) {
                                leaveQueue()
                                showingReviewPopup = true
                            },
                            secondaryButton: .cancel(Text("No"))
                        )
                    }
                    
                    // Conditional NavigationLink
                    NavigationLink(destination: ContentView(refreshManager: refreshManager), isActive: $navigateToContentView) {
                        EmptyView()
                    }
                    .hidden() // Initially hidden
                    
                    // Review popup overlay
                    if showingReviewPopup {
                        ReviewPopup(isPresented: $showingReviewPopup, navigateToContentView: $navigateToContentView, rating: $rating, userComment: $userComment)
                    }
                }
                .navigationBarHidden(true)
                .onReceive(refreshManager.$shouldRefresh) { _ in
                    refreshQueuePosition()
                }
                
                // Chat bubble icon
                Button(action: {
                    // Show comments popup
                    showingCommentsPopup = true
                }) {
                    Image(systemName: "message.circle.fill")
                        .font(.system(size: 32))
                        .foregroundColor(.blue)
                        .padding()
                }
                .buttonStyle(PlainButtonStyle())
                .offset(x: -16, y: -50) // Adjust offset to position the chat icon above the 'Leave Queue' button
                
                // Comments popup overlay
                if showingCommentsPopup {
                    CommentsPopup(isPresented: $showingCommentsPopup)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.black.opacity(0.4).edgesIgnoringSafeArea(.all))
                }
            }
        }
    }
    
    func refreshQueuePosition() {
        queuePosition = CoreDataManager.shared.getQueueCount()
    }
    
    func leaveQueue() {
        // Subtract peopleJoining from queueCount
        var queueCount = CoreDataManager.shared.getQueueCount()
        queueCount = queueCount - peopleJoining
        CoreDataManager.shared.saveQueueCount(queueCount)
        
        // Update queuePosition immediately
        queuePosition = queueCount
    }
    
    func ReviewPopup(isPresented: Binding<Bool>, navigateToContentView: Binding<Bool>, rating: Binding<Int>, userComment: Binding<String>) -> some View {
        
        return VStack(spacing: 20) {
            Text("Rate Your Experience")
                .font(.headline)
            StarRatingView(rating: rating)
            
            Text("Please share your comments")
                .font(.subheadline)
                .padding(.top, 10)
            Text("and advice:")
                .font(.subheadline)
                .multilineTextAlignment(.leading)
            
            
            TextField("Enter your comment", text: userComment)
                .frame(height: 100)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
                .padding(.horizontal)
            
            HStack {
                Button(action: {
                    // Handle the submit action
                    isPresented.wrappedValue = false
                    navigateToContentView.wrappedValue = true
                    
                    // Save user comment
                    CoreDataManager.shared.saveUserComment(userComment.wrappedValue)
                    
                    // Optionally print or handle the user's rating and comment
                    print("User's rating: \(rating.wrappedValue) out of 5")
                    print("User's comment: \(userComment.wrappedValue)")
                }) {
                    Text("Submit")
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                Button(action: {
                    // Handle the cancel action
                    isPresented.wrappedValue = false
                    navigateToContentView.wrappedValue = true
                }) {
                    Text("Cancel")
                        .padding()
                        .background(Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(radius: 10)
        .frame(maxWidth: 300)
    }
    
    struct StarRatingView: View {
        @Binding var rating: Int
        
        var body: some View {
            HStack {
                ForEach(1..<6) { index in
                    Image(systemName: index <= rating ? "star.fill" : "star")
                        .foregroundColor(index <= rating ? .yellow : .gray)
                        .onTapGesture {
                            rating = index
                        }
                }
            }
        }
    }
    
    struct CommentsPopup: View {
        @Binding var isPresented: Bool
        
        var body: some View {
            VStack {
                Text("User Comments")
                    .font(.headline)
                    .padding(.top)
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(CoreDataManager.shared.getAllUserComments(), id: \.self) { comment in
                            Text(comment)
                                .padding()
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(8)
                        }
                    }
                }
                .frame(height: 200) // Adjust height as needed
                
                Button(action: {
                    // Handle close action
                    isPresented = false
                }) {
                    Text("Close")
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .padding(.top)
            }
            .padding()
            .background(Color.white)
            .cornerRadius(12)
            .shadow(radius: 10)
            .frame(maxWidth: 300)
        }
    }
}

