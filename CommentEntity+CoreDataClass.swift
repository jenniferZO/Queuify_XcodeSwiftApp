//
//  CommentEntity+CoreDataClass.swift
//  Queue
//
//  Created by Zhao, Jennifer (OXF) Student on 11/07/2024.
//
//

import Foundation
import CoreData

//@objc(CommentEntity)
public class CommentEntity: NSManagedObject {
    @NSManaged public var commentTextE: String?
}
