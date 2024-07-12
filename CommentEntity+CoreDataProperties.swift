//
//  CommentEntity+CoreDataProperties.swift
//  Queue
//
//  Created by Zhao, Jennifer (OXF) Student on 11/07/2024.
//
//

import Foundation
import CoreData


extension CommentEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<CommentEntity> {
        return NSFetchRequest<CommentEntity>(entityName: "CommentEntity")
    }

}

extension CommentEntity : Identifiable {

}
