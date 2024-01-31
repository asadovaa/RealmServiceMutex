//
//  ViewController.swift
//  RealmServiceForMutex
//
//  Created by Aynur Asadova on 2024-01-31.
//

import UIKit
import RealmSwift

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }

    @IBAction func centerButton(_ sender: UIButton) {
        testConcurrentAccessWithFatalError()
    }
    
    func testConcurrentAccessWithFatalError() {
        let test = RealmConcurrentTest()
        test.setupTestData()
        test.deleteItem() // Deletes the item on the main thread
        test.accessDeletedItem() // Tries to access the deleted item on a background thread
    }

}

// MARK: Uncomment this buggy code to get crash

// This class demonstrates a common mistake in handling Realm objects across threads.
// It directly manipulates Realm objects without considering thread safety, leading to crashes.

//class RealmConcurrentTest {
//    private var realm: Realm!
//    var testItem: Item?
//
//    init() {
//        realm = try! Realm()
//    }
//

//    // Sets up test data by writing a new Item to the Realm database.
//    // It incorrectly stores a direct reference to the Realm object, which is not thread-safe.
//    func setupTestData() {
//        try! realm.write {
//            let newItem = Item(name: "Test Item")
//            realm.add(newItem, update: .modified)
//            self.testItem = newItem // Storing a direct reference to the Realm object
//        }
//    }
//
//    // Deletes the test item. This operation itself is safe.
//    func deleteItem() {
//        if let itemToDelete = self.testItem {
//            try! realm.write {
//                realm.delete(itemToDelete)
//            }
//        }
//    }
//
//    // Tries to access the deleted item from a background thread.
//    // This causes a crash because the item has been deleted and is being accessed
//    // from a different thread, violating Realm's thread safety rules.
//    func accessDeletedItem() {
//        DispatchQueue.global().async {
//            // Directly accessing the stored Realm object reference in a background thread
//            if let item = self.testItem {
//                print("Item name: \(item.name)") // This line should cause the crash
//            }
//        }
//    }
//}


// MARK: if you uncomment above, comment below code

// This class demonstrates a correct and safe way to handle Realm objects across threads.
// It uses a `RealmServiceWithLock` to manage thread safety, preventing crashes.

class RealmConcurrentTest {
    private var realmService = RealmServiceWithLock()
    private var itemId: String?

    init() {
        setupTestData()
    }
    
    // Sets up test data in a thread-safe manner using `RealmServiceWithLock`.
    // Instead of storing a direct object reference, it stores only the item ID.
    func setupTestData() {
        realmService.performWrite {
            let newItem = Item(name: "Test Item")
                       let realm = try! Realm()
                       realm.add(newItem, update: .modified)
                       self.itemId = newItem.id
        }
    }

    // Deletes the item in a thread-safe way using `RealmServiceWithLock`.
    func deleteItem() {
        guard let itemId = self.itemId else { return }
        realmService.performWrite {
            let realm = try! Realm()
            if let itemToDelete = realm.object(ofType: Item.self, forPrimaryKey: itemId) {
                realm.delete(itemToDelete)
            }
        }
    }

    // Tries to access the potentially deleted item from a background thread in a safe way.
    // It uses `RealmServiceWithLock` to ensure thread-safe read operations.
    // This prevents crashes by ensuring thread-safe access to the Realm object.
    func accessDeletedItem() {
        guard let itemId = self.itemId else { return }
        DispatchQueue.global().async {
            let item = self.realmService.performRead {
                let realm = try! Realm()
                return realm.object(ofType: Item.self, forPrimaryKey: itemId)
            }
            
            if let item = item {
                print("Item name: \(item.name)")
            } else {
                print("Item not found or already deleted")
            }
        }
    }
}
