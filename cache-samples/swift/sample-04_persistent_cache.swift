// sample-04_persistent_cache.swift
// Codable persistent cache — stores simple codable values to disk.
import Foundation

struct Item: Codable {
    let key: String
    let value: String
    let expires: Date
}

final class PersistentCache {
    private var dict: [String:Item] = [:]
    private let url: URL
    init(filename: String = "pcache.json"){
        self.url = URL(fileURLWithPath: FileManager.default.currentDirectoryPath).appendingPathComponent(filename)
        load()
    }
    func put(key: String, value: String, ttl: TimeInterval){ dict[key] = Item(key: key, value: value, expires: Date().addingTimeInterval(ttl)); save() }
    func get(key: String) -> String?{ guard let it = dict[key], it.expires > Date() else { dict.removeValue(forKey: key); return nil }; return it.value }
    private func save(){ if let data=try? JSONEncoder().encode(Array(dict.values)) { try? data.write(to: url) } }
    private func load(){ if let data=try? Data(contentsOf: url), let arr = try? JSONDecoder().decode([Item].self, from: data) { dict = Dictionary(uniqueKeysWithValues: arr.map{ ($0.key, $0) }) } }
}

// Demo
let pc = PersistentCache()
pc.put(key: "hello", value: "world", ttl: 3600)
if let v = pc.get(key: "hello") { print("hello=\(v)") }
