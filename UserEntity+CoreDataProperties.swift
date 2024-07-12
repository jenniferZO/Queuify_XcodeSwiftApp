//
//  UserEntity+CoreDataProperties.swift
//  Queue
//
//  Created by Zhao, Jennifer (OXF) Student on 11/07/2024.
//
//

import Foundation
import CoreData

extension UserEntity {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<UserEntity> {
        return NSFetchRequest<UserEntity>(entityName: "UserEntity")
    }
}
