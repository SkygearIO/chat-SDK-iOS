//
//  SKYAssetCache.swift
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

public protocol SKYAssetCache {
    func get(asset: SKYAsset) -> Data?
    func set(data: Data, for asset: SKYAsset)
    func purge(asset: SKYAsset)
    func purgeAll()
}

public class SKYAssetMemoryCache: SKYAssetCache {
    let store: MemoryDataCache

    private static var sharedInstance: SKYAssetMemoryCache? = nil

    static func shared() -> SKYAssetMemoryCache {
        if self.sharedInstance == nil {
            self.sharedInstance = SKYAssetMemoryCache()
        }

        return self.sharedInstance!
    }

    public init(maxSize: Int) {
        self.store = MemoryDataCache(maxSize: maxSize)
    }

    public convenience init() {
        self.init(maxSize: 100)
    }

    public func get(asset: SKYAsset) -> Data? {
        return self.store.getData(forKey: asset.name)
    }

    public func set(data: Data, for asset: SKYAsset) {
        self.store.set(data: data, forKey: asset.name)
    }

    public func purge(asset: SKYAsset) {
        self.store.purgeData(forKey: asset.name)
    }

    public func purgeAll() {
        self.store.purgeAll()
    }
}

