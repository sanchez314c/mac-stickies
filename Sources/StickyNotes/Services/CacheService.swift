//
//  CacheService.swift
//  StickyNotes
//
//  Comprehensive caching system for performance optimization
//

import Combine
import Foundation
import SwiftUI

class CacheService {
    static let shared = CacheService()

    // MARK: - LRU Cache for Rendered Content

    private let renderedContentCache = LRUCache<UUID, RenderedNoteContent>(capacity: 100)
    private let previewCache = LRUCache<UUID, NotePreview>(capacity: 200)

    // MARK: - Search Cache

    private let searchCache = LRUCache<String, [NoteMetadata]>(capacity: 50)
    private var searchCacheTimestamps: [String: Date] = [:]
    private let searchCacheTimeout: TimeInterval = 300 // 5 minutes

    // MARK: - Metadata Cache

    private var metadataCache: [UUID: NoteMetadata] = [:]
    private var metadataCacheTimestamp: Date?
    private let metadataCacheTimeout: TimeInterval = 60 // 1 minute

    private let cacheQueue = DispatchQueue(label: "com.stickynotes.cache", qos: .utility)
    private var cancellables = Set<AnyCancellable>()

    private init() {
        setupMemoryWarningObserver()
    }

    // MARK: - Rendered Content Caching

    func cacheRenderedContent(for note: Note, content: RenderedNoteContent) {
        cacheQueue.async {
            self.renderedContentCache.set(note.id, content)
        }
    }

    func getRenderedContent(for noteId: UUID) -> RenderedNoteContent? {
        return cacheQueue.sync {
            renderedContentCache.get(noteId)
        }
    }

    func cachePreview(for note: Note, preview: NotePreview) {
        cacheQueue.async {
            self.previewCache.set(note.id, preview)
        }
    }

    func getPreview(for noteId: UUID) -> NotePreview? {
        return cacheQueue.sync {
            previewCache.get(noteId)
        }
    }

    // MARK: - Search Caching

    func cacheSearchResults(query: String, results: [NoteMetadata]) {
        let cacheKey = query.lowercased()
        cacheQueue.async {
            self.searchCache.set(cacheKey, results)
            self.searchCacheTimestamps[cacheKey] = Date()
        }
    }

    func getSearchResults(query: String) -> [NoteMetadata]? {
        let cacheKey = query.lowercased()
        return cacheQueue.sync {
            guard let results = searchCache.get(cacheKey),
                  let timestamp = searchCacheTimestamps[cacheKey],
                  Date().timeIntervalSince(timestamp) < searchCacheTimeout
            else {
                return nil
            }
            return results
        }
    }

    // MARK: - Metadata Caching

    func cacheMetadata(_ metadata: [NoteMetadata]) {
        cacheQueue.async {
            self.metadataCache = Dictionary(uniqueKeysWithValues: metadata.map { ($0.id, $0) })
            self.metadataCacheTimestamp = Date()
        }
    }

    func getMetadata(for noteId: UUID) -> NoteMetadata? {
        return cacheQueue.sync {
            guard let timestamp = metadataCacheTimestamp,
                  Date().timeIntervalSince(timestamp) < metadataCacheTimeout
            else {
                return nil
            }
            return metadataCache[noteId]
        }
    }

    func getAllMetadata() -> [NoteMetadata]? {
        return cacheQueue.sync {
            guard let timestamp = metadataCacheTimestamp,
                  Date().timeIntervalSince(timestamp) < metadataCacheTimeout
            else {
                return nil
            }
            return Array(metadataCache.values)
        }
    }

    // MARK: - Cache Invalidation

    func invalidateNote(_ noteId: UUID) {
        cacheQueue.async {
            self.renderedContentCache.remove(noteId)
            self.previewCache.remove(noteId)
            self.metadataCache.removeValue(forKey: noteId)
        }
    }

    func invalidateSearchCache() {
        cacheQueue.async {
            self.searchCache.clear()
            self.searchCacheTimestamps.removeAll()
        }
    }

    func invalidateAll() {
        cacheQueue.async {
            self.renderedContentCache.clear()
            self.previewCache.clear()
            self.searchCache.clear()
            self.metadataCache.removeAll()
            self.searchCacheTimestamps.removeAll()
            self.metadataCacheTimestamp = nil
        }
    }

    // MARK: - Memory Management

    private func setupMemoryWarningObserver() {
        NotificationCenter.default.publisher(for: UIApplication.didReceiveMemoryWarningNotification)
            .sink { [weak self] _ in
                self?.handleMemoryWarning()
            }
            .store(in: &cancellables)
    }

    private func handleMemoryWarning() {
        cacheQueue.async {
            // Reduce cache sizes during memory pressure
            self.renderedContentCache.reduceCapacity(to: 50)
            self.previewCache.reduceCapacity(to: 100)
            self.searchCache.reduceCapacity(to: 25)
        }
    }

    // MARK: - Cache Statistics

    func getCacheStatistics() -> CacheStatistics {
        return cacheQueue.sync {
            CacheStatistics(
                renderedContentCount: renderedContentCache.count,
                previewCount: previewCache.count,
                searchResultsCount: searchCache.count,
                metadataCount: metadataCache.count
            )
        }
    }
}

// MARK: - LRU Cache Implementation

class LRUCache<Key: Hashable, Value> {
    private let capacity: Int
    private var cache: [Key: Value] = [:]
    private var accessOrder: [Key] = []

    init(capacity: Int) {
        self.capacity = capacity
    }

    func get(_ key: Key) -> Value? {
        guard let value = cache[key] else { return nil }

        // Move to front (most recently used)
        if let index = accessOrder.firstIndex(of: key) {
            accessOrder.remove(at: index)
        }
        accessOrder.insert(key, at: 0)

        return value
    }

    func set(_ key: Key, _ value: Value) {
        if cache[key] == nil {
            // New entry
            if accessOrder.count >= capacity {
                // Remove least recently used
                let lruKey = accessOrder.removeLast()
                cache.removeValue(forKey: lruKey)
            }
        } else {
            // Existing entry, remove from current position
            if let index = accessOrder.firstIndex(of: key) {
                accessOrder.remove(at: index)
            }
        }

        cache[key] = value
        accessOrder.insert(key, at: 0)
    }

    func remove(_ key: Key) {
        cache.removeValue(forKey: key)
        if let index = accessOrder.firstIndex(of: key) {
            accessOrder.remove(at: index)
        }
    }

    func clear() {
        cache.removeAll()
        accessOrder.removeAll()
    }

    func reduceCapacity(to newCapacity: Int) {
        while accessOrder.count > newCapacity {
            let lruKey = accessOrder.removeLast()
            cache.removeValue(forKey: lruKey)
        }
    }

    var count: Int {
        cache.count
    }
}

// MARK: - Supporting Types

struct RenderedNoteContent {
    let attributedString: NSAttributedString
    let renderedSize: CGSize
    let lastModified: Date
}

struct NotePreview {
    let title: String
    let previewText: String
    let color: NoteColor
    let lastModified: Date
}

struct CacheStatistics {
    let renderedContentCount: Int
    let previewCount: Int
    let searchResultsCount: Int
    let metadataCount: Int
}
