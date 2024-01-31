//
//  RealmService.swift
//  RealmServiceForMutex
//
//  Created by Aynur Asadova on 2024-01-31.
//

import Foundation
import RealmSwift

class RealmServiceWithLock {
    private var lock = NSLock()

    func performWrite(_ block: @escaping () -> Void) {
        lock.lock()
        defer { lock.unlock() }

        let realm = try! Realm()
        try! realm.write(block)
    }

    func performRead<T>(_ block: () -> T) -> T {
        lock.lock()
        defer { lock.unlock() }

        return block()
    }
}

class RealmServiceWithSemaphore {
    private var semaphore = DispatchSemaphore(value: 1)

    func updateObject(_ block: () -> Void) {
        semaphore.wait()
        defer { semaphore.signal() }
        
        // Perform Realm transaction
        let realm = try! Realm()
        try! realm.write {
            block()
        }
    }
}
