//
//  NoteEntity.swift
//  StickyNotes
//
//  Created on 2025-01-21.
//

import Foundation
import CoreData

/// Core Data entity for Note persistence
@objc(NoteEntity)
public class NoteEntity: NSManagedObject {
    @NSManaged public var id: UUID?
    @NSManaged public var title: String?
    @NSManaged public var content: String?
    @NSManaged public var color: String?
    @NSManaged public var positionX: Double
    @NSManaged public var positionY: Double
    @NSManaged public var width: Double
    @NSManaged public var height: Double
    @NSManaged public var createdAt: Date?
    @NSManaged public var modifiedAt: Date?
    @NSManaged public var isMarkdown: Bool
    @NSManaged public var isLocked: Bool
    @NSManaged public var tags: NSObject?
}

extension NoteEntity {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<NoteEntity> {
        return NSFetchRequest<NoteEntity>(entityName: "Note")
    }

    @nonobjc public class func fetchRequestSortedByModifiedDate() -> NSFetchRequest<NoteEntity> {
        let request = fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "modifiedAt", ascending: false)]
        return request
    }

    @nonobjc public class func fetchRequestForNote(withId id: UUID) -> NSFetchRequest<NoteEntity> {
        let request = fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1
        return request
    }

    @nonobjc public class func fetchRequestForNotes(containing searchText: String) -> NSFetchRequest<NoteEntity> {
        let request = fetchRequest()
        let titlePredicate = NSPredicate(format: "title CONTAINS[cd] %@", searchText)
        let contentPredicate = NSPredicate(format: "content CONTAINS[cd] %@", searchText)
        request.predicate = NSCompoundPredicate(orPredicateWithSubpredicates: [titlePredicate, contentPredicate])
        request.sortDescriptors = [NSSortDescriptor(key: "modifiedAt", ascending: false)]
        return request
    }

    @nonobjc public class func fetchRequestForNotes(withColor color: String) -> NSFetchRequest<NoteEntity> {
        let request = fetchRequest()
        request.predicate = NSPredicate(format: "color == %@", color)
        request.sortDescriptors = [NSSortDescriptor(key: "modifiedAt", ascending: false)]
        return request
    }

    @nonobjc public class func fetchRequestForNotes(withTags tags: [String]) -> NSFetchRequest<NoteEntity> {
        let request = fetchRequest()
        let predicates = tags.map { NSPredicate(format: "ANY tags == %@", $0) }
        request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        request.sortDescriptors = [NSSortDescriptor(key: "modifiedAt", ascending: false)]
        return request
    }
}