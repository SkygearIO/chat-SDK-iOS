//
//  SKYAsset+Cache.swift
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

public protocol SKYAssetCache {
    func get(asset: SKYAsset) -> Any?
    func set(value: Any, for asset: SKYAsset)
    func purge(asset: SKYAsset)
    func purgeAll()
}

extension SKYAssetCache {
}

public class SKYAssetMemoryCache: SKYAssetCache {
    let store: LruCache

    static func shared() -> SKYAssetMemoryCache {
        return sharedMemoryCache
    }

    public init(maxSize: Int) {
        self.store = LruCache(maxSize: maxSize)
    }

    public convenience init() {
        self.init(maxSize: 100)
    }

    public func get(asset: SKYAsset) -> Any? {
        return self.store.get(asset.name)
    }

    public func set(value: Any, for asset: SKYAsset) {
        self.store.put(asset.name, value: value)
    }

    public func purge(asset: SKYAsset) {
        self.store.remove(asset.name)
    }

    public func purgeAll() {
        self.store.evictAll()
    }
}

let sharedMemoryCache: SKYAssetMemoryCache = SKYAssetMemoryCache()
