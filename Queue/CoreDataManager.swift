
import Foundation
import CoreData

class CoreDataManager {
    static let shared = CoreDataManager()
    
    private init() {}
    
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "CoreData") // Replace with your data model name
        container.loadPersistentStores { _, error in
            if let error = error {
                fatalError("Failed to load Core Data stack: \(error)")
            }
        }
        return container
    }()
    
    func saveUserIDToCoreData(userID: String) {
        let context = persistentContainer.viewContext
        
        // Fetch and delete all existing UserEntity objects
        let fetchRequest: NSFetchRequest<UserEntity> = UserEntity.fetchRequest()
        
        do {
            let users = try context.fetch(fetchRequest)
            for user in users {
                context.delete(user)
            }
            
            // Save the new userID
            let user = UserEntity(context: context)
            user.userIDE = userID
            try context.save()
        } catch {
            print("Failed to save userID in Core Data: \(error.localizedDescription)")
        }
    }
    
    func getUserID() -> String? {
        let context = persistentContainer.viewContext
        let fetchRequest: NSFetchRequest<UserEntity> = UserEntity.fetchRequest()
        
        do {
            let users = try context.fetch(fetchRequest)
            return users.first?.userIDE
        } catch {
            print("Failed to fetch userID from Core Data: \(error.localizedDescription)")
            return nil
        }
    }
    
    // MARK: - Comment Operations
    
    func saveUserComment(_ comment: String) {
        let context = persistentContainer.viewContext
        context.perform {
            let commentEntity = CommentEntity(context: context)
            commentEntity.commentTextE = comment
            
            do {
                try context.save()
            } catch {
                print("Failed to save comment in Core Data: \(error.localizedDescription)")
            }
        }
    }
    
    func getAllUserComments() -> [String] {
        let context = persistentContainer.viewContext
        let fetchRequest: NSFetchRequest<CommentEntity> = CommentEntity.fetchRequest()
        
        do {
            let comments = try context.fetch(fetchRequest)
            return comments.map { $0.commentTextE ?? "" }
        } catch {
            print("Failed to fetch comments from Core Data: \(error.localizedDescription)")
            return []
        }
    }
}

