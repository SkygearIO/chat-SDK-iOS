//
//  DataCache.swift
//  SKYKitChat
//
//  Copyright 2016 Oursky Ltd.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

import LruCache

@objc public protocol DataCache {
    func getData(forKey key: String) -> Data?
    func set(data: Data, forKey key: String)
    func purgeData(forKey key: String)
    func purgeAll()
}

@objcMembers
public class MemoryDataCache: DataCache {
    let store: LruCache

    private static var sharedInstance: MemoryDataCache?

    static func shared() -> MemoryDataCache {
        if self.sharedInstance == nil {
            self.sharedInstance = MemoryDataCache()
        }

        return self.sharedInstance!
    }

    init(maxSize: Int) {
        self.store = LruCache(maxSize: maxSize)
    }

    convenience init() {
        self.init(maxSize: 100)
    }

    public func getData(forKey key: String) -> Data? {
        return self.store.get(key) as? Data
    }

    public func set(data: Data, forKey key: String) {
        self.store.put(key, value: data)
    }

    public func purgeData(forKey key: String) {
        self.store.remove(key)
    }

    public func purgeAll() {
        self.store.evictAll()
    }
}
