// sample-03_generic_cache.swift
// Generic Swift cache with TTL and optionally async loader
import Foundation

final class GenericCache<Key: Hashable, Value> {
    private let ttl: TimeInterval
    private var store: [Key:(value: Value, expires: Date)] = [:]
    private let queue = DispatchQueue(label: "com.example.cache", attributes: .concurrent)
    init(ttl: TimeInterval){ self.ttl = ttl }
    func put(_ k: Key, _ v: Value){ queue.async(flags: .barrier){ self.store[k] = (v, Date().addingTimeInterval(self.ttl)) } }
    func get(_ k: Key) -> Value? {
        var res: Value?
        queue.sync{ if let e = self.store[k], e.expires > Date() { res = e.value } else { self.store.removeValue(forKey: k) } }
        return res
    }
    func getOrLoad(_ k: Key, loader: @escaping () async -> Value) async -> Value {
        if let v = get(k) { return v }
        let v = await loader()
        put(k, v)
        return v
    }
}

// Usage example (async main)
@main
struct App {
    static func main() async {
        let cache = GenericCache<String,String>(ttl: 2.0)
        let v = await cache.getOrLoad("time") {
            try? await Task.sleep(nanoseconds: 200_000_000)
            return "loaded-\(Date())"
        }
        print(v)
        // demonstrate TTL expiry
        try? await Task.sleep(nanoseconds: 2_200_000_000)
        if cache.get("time") == nil { print("expired") }
    }
}
