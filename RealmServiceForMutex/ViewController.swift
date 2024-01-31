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

//Buggy code

//class RealmConcurrentTest {
//    private var realm: Realm!
//    var testItem: Item?
//
//    init() {
//        realm = try! Realm()
//    }
//
//    func setupTestData() {
//        try! realm.write {
//            let newItem = Item(name: "Test Item")
//            realm.add(newItem, update: .modified)
//            self.testItem = newItem // Storing a direct reference to the Realm object
//        }
//    }
//
//    func deleteItem() {
//        if let itemToDelete = self.testItem {
//            try! realm.write {
//                realm.delete(itemToDelete)
//            }
//        }
//    }
//
//    func accessDeletedItem() {
//        DispatchQueue.global().async {
//            // Directly accessing the stored Realm object reference in a background thread
//            if let item = self.testItem {
//                print("Item name: \(item.name)") // This line should cause the crash
//            }
//        }
//    }
//}

class RealmConcurrentTest {
    private var realmService = RealmServiceWithLock()
    private var itemId: String?

    init() {
        setupTestData()
    }

    func setupTestData() {
        realmService.performWrite {
            let newItem = Item(name: "Test Item")
                       let realm = try! Realm()
                       realm.add(newItem, update: .modified)
                       self.itemId = newItem.id
        }
    }

    func deleteItem() {
        guard let itemId = self.itemId else { return }
        realmService.performWrite {
            let realm = try! Realm()
            if let itemToDelete = realm.object(ofType: Item.self, forPrimaryKey: itemId) {
                realm.delete(itemToDelete)
            }
        }
    }

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
