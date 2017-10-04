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

protocol SKYAssetCache {
    func get(asset: SKYAsset) -> Any?
    func set(value: Any, for asset: SKYAsset)
    func purge(asset: SKYAsset)
    func purgeAll()
}

extension SKYAssetCache {
}

class SKYAssetMemoryCache: SKYAssetCache {
    let store: LruCache

    static func shared() -> SKYAssetMemoryCache {
        return sharedMemoryCache
    }

    init() {
        self.store = LruCache(maxSize: 100)
    }

    func get(asset: SKYAsset) -> Any? {
        return self.store.get(asset.name)
    }

    func set(value: Any, for asset: SKYAsset) {
        self.store.put(asset.name, value: value)
    }

    func purge(asset: SKYAsset) {
        self.store.remove(asset.name)
    }

    func purgeAll() {
        self.store.evictAll()
    }
}

let sharedMemoryCache: SKYAssetMemoryCache = SKYAssetMemoryCache()
