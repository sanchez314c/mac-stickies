//
//  PersistenceController.swift
//  StickyNotes
//
//  Created by SuperClaude
//  Copyright © 2024 SuperClaude. All rights reserved.
//

import CoreData
import StickyNotesCore

struct PersistenceController {
    static let shared = PersistenceController()

    let container: NSPersistentContainer

    init(inMemory: Bool = true) {
        // Use DataModel.loadModel() to get the model (works for both bundle and programmatic)
        let model = DataModel.loadModel()
        container = NSPersistentContainer(name: "StickyNotes", managedObjectModel: model)

        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }

        container.loadPersistentStores { storeDescription, error in
            if let error = error as NSError? {
                print("Core Data error: \(error), \(error.userInfo)")
                // Continue anyway for demo purposes
            }
        }

        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }

    // MARK: - Helper Methods

    func save() throws {
        let context = container.viewContext
        if context.hasChanges {
            try context.save()
        }
    }

    func createNote(title: String = "", content: String = "", color: String = "#FFE4B5") -> Note {
        let note = Note(context: container.viewContext)
        note.title = title
        note.content = content
        note.color = color
        return note
    }

    func deleteNote(_ note: Note) throws {
        let context = container.viewContext
        context.delete(note)
        try context.save()
    }

    func fetchNotes(predicate: NSPredicate? = nil, sortDescriptors: [NSSortDescriptor]? = nil) throws -> [Note] {
        let request = Note.fetchRequest()
        request.predicate = predicate
        request.sortDescriptors = sortDescriptors
        return try container.viewContext.fetch(request)
    }

    func searchNotes(query: String) throws -> [Note] {
        let titlePredicate = NSPredicate(format: "title CONTAINS[cd] %@", query)
        let contentPredicate = NSPredicate(format: "content CONTAINS[cd] %@", query)
        let compoundPredicate = NSCompoundPredicate(orPredicateWithSubpredicates: [titlePredicate, contentPredicate])

        let sortDescriptor = NSSortDescriptor(key: "updatedAt", ascending: false)
        return try fetchNotes(predicate: compoundPredicate, sortDescriptors: [sortDescriptor])
    }

    func notesByCategory(_ category: String) throws -> [Note] {
        let predicate = NSPredicate(format: "category == %@", category)
        let sortDescriptor = NSSortDescriptor(key: "updatedAt", ascending: false)
        return try fetchNotes(predicate: predicate, sortDescriptors: [sortDescriptor])
    }

    func pinnedNotes() throws -> [Note] {
        let predicate = NSPredicate(format: "isPinned == true")
        let sortDescriptor = NSSortDescriptor(key: "updatedAt", ascending: false)
        return try fetchNotes(predicate: predicate, sortDescriptors: [sortDescriptor])
    }

    // MARK: - Migration Support

    static var preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext

        // Create sample data for preview
        for i in 1...5 {
            let note = Note(context: viewContext)
            note.title = "Sample Note \(i)"
            note.content = "This is sample content for note \(i). It contains some text to demonstrate the note functionality."
            note.color = ["#FFE4B5", "#E6E6FA", "#F0FFF0", "#FFF8DC", "#F5DEB3"][i % 5]
            note.isPinned = i == 1
            note.category = ["Work", "Personal", "Ideas", "Shopping", "Reminders"][i % 5]
        }

        do {
            try viewContext.save()
        } catch {
            // Preview data failure should not crash the app
            let nsError = error as NSError
            print("Preview data save error: \(nsError), \(nsError.userInfo)")
        }

        return result
    }()
}