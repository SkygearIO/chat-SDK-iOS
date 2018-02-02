//
//  SimpleDownloadDispatcher.swift
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

class SimpleDownloadDispatcher {
    fileprivate static var sharedInstance: SimpleDownloadDispatcher?

    private var items: [String: SimpleDownloadDispatchItem] = [:]

    static func `default`() -> SimpleDownloadDispatcher {
        if self.sharedInstance == nil {
            self.sharedInstance = SimpleDownloadDispatcher()
        }

        return self.sharedInstance!
    }

    func download(_ urlString: String,
                  compltion block: ((_ data: Data?) -> Void)? = nil
        ) -> SimpleDownloadDispatchItemCallback? {
        let item: SimpleDownloadDispatchItem

        if let found = self.items[urlString] {
            item = found
        } else {
            item = SimpleDownloadDispatchItem(urlString: urlString)
            self.items[urlString] = item
        }

        var callback: SimpleDownloadDispatchItemCallback? = nil
        if let callbackBlock = block {
            callback = SimpleDownloadDispatchItemCallback(callbackBlock)
            item.add(callback: callback!)
        }

        item.start { _ in self.items.removeValue(forKey: urlString) }
        return callback
    }

    func cancel(_ urlString: String, callback: SimpleDownloadDispatchItemCallback) {
        guard let item = self.items[urlString] else {
            print("Warning: Cannot find Download Item (url: \(urlString))")
            return
        }

        _ = item.remove(callback: callback)
    }
}

class SimpleDownloadDispatchItem {
    private let urlString: String
    private var data: Data?
    private(set) var started = false
    private(set) var callbacks: [SimpleDownloadDispatchItemCallback] = []

    init(urlString: String) {
        self.urlString = urlString
    }

    func start(done: ((_ data: Data?) -> Void)? = nil) {
        guard !self.started else {
            // do nothing
            return
        }

        self.started = true
        DispatchQueue.global().async {
            self.data = try? Data(contentsOf: URL(string: self.urlString)!)

            DispatchQueue.main.async {
                for callback in self.callbacks {
                    callback.invoke(data: self.data)
                }

                done?(self.data)
            }
        }
    }

    func add(callback: SimpleDownloadDispatchItemCallback) {
        if !self.callbacks.contains(callback) {
            self.callbacks.append(callback)
        }
    }

    func remove(callback: SimpleDownloadDispatchItemCallback) -> Bool {
        if let idx = self.callbacks.index(of: callback) {
            self.callbacks.remove(at: idx)
            return true
        }

        return false
    }
}

class SimpleDownloadDispatchItemCallback: Equatable {
    static func ==(lhs: SimpleDownloadDispatchItemCallback,
                   rhs: SimpleDownloadDispatchItemCallback) -> Bool {
        return lhs.id == lhs.id
    }

    private let id: Int
    private let block: ((_ data: Data?) -> Void)

    init(_ block: @escaping (_ data: Data?) -> Void) {
        self.id = Int(arc4random())
        self.block = block
    }

    func invoke(data: Data?) {
        self.block(data)
    }
}
