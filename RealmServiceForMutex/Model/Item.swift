//
//  Item.swift
//  RealmServiceForMutex
//
//  Created by Aynur Asadova on 2024-01-31.
//

import Foundation
import RealmSwift

class Item: Object {
    @Persisted var id = UUID().uuidString
    @Persisted var name: String

    convenience init(name: String) {
        self.init()
        self.name = name
    }

    override static func primaryKey() -> String? {
        return "id"
    }
}
