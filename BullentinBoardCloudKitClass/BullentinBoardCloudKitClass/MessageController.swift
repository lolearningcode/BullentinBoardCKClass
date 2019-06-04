//
//  MessageController.swift
//  BullentinBoardCloudKitClass
//
//  Created by Lo Howard on 6/3/19.
//  Copyright © 2019 Lo Howard. All rights reserved.
//

import Foundation
import CloudKit

class MessageController {
    static let shared = MessageController()
    var messages: [Message] = []
    let privateDB = CKContainer.default().privateCloudDatabase
    
    func createMessage(text: String, timestamp: Date, completion: @escaping (Bool) -> Void) {
        let message = Message(text: text, timestamp: timestamp)
        self.saveMessage(message: message, completion: completion)
    }
    
    func remove(message: Message, completion: @escaping (Bool) -> ()) {
        
        guard let index = MessageController.shared.messages.firstIndex(of: message) else { return }
        MessageController.shared.messages.remove(at: index)
        privateDB.delete(withRecordID: message.ckRecordID) { (_, error) in
            if let error = error {
                print("Error removing: \(error.localizedDescription)")
                completion(false)
                return
            } else {
                print("Message deleted!!!")
                completion(true)
            }
        }
    }
    
    func saveMessage(message: Message, completion: @escaping (Bool) -> ()) {
        let messageRecord = CKRecord(message: message)
        privateDB.save(messageRecord) { (record, error) in
            if let error = error {
                print("Error saving: \(error.localizedDescription)")
                completion(false)
                return
            }
            guard let record = record, let message = Message(ckRecord: record) else { completion(false); return }
            self.messages.append(message)
            completion(true)
        }
    }
    
    func fetchMessages(completion: @escaping (Bool) -> ()) {
        let predicate = NSPredicate(value: true)
        let query = CKQuery(recordType: Constants.recordKey, predicate: predicate)
        privateDB.perform(query, inZoneWith: nil) { (records, error) in
            if let error = error {
                print("Error fetching: \(error.localizedDescription)")
                completion(false)
                return
            }
            
            guard let records = records else { completion(false); return }
            var messages = records.compactMap({Message(ckRecord: $0)})
            messages.sort { $0.timestamp < $1.timestamp }
            self.messages = messages
            completion(true)
        }
    }
    
    func subscribeToNotifications(completion: @escaping (Error?) -> Void) {
        
        let predicate = NSPredicate(value: true)
        
        let subscription = CKQuerySubscription(recordType: Constants.recordKey, predicate: predicate, options: .firesOnRecordCreation)
        
        let notificationInfo = CKSubscription.NotificationInfo()
        notificationInfo.alertBody = "New Post! Would you look at the app?"
        notificationInfo.shouldBadge = true
        notificationInfo.soundName = "default"
        
        subscription.notificationInfo = notificationInfo
        
        privateDB.save(subscription) { (_, error) in
            if let error = error {
                print("Error subscription: \(error.localizedDescription)")
                completion(error)
                return
            }
            completion(nil)
        }
    }
    
    func requestDiscoverabilityAuth(completion: @escaping (CKContainer_Application_PermissionStatus, Error?) -> Void) {
        
        CKContainer.default().status(forApplicationPermission: .userDiscoverability) { (status, error) in
            guard status != .granted else { completion(.granted, error); return }
        }
        CKContainer.default().requestApplicationPermission(.userDiscoverability, completionHandler: completion)
    }
    
    func fetchAllDiscoverableUsers(completion: @escaping ([CKUserIdentity], Error?) -> Void) {
        let discoverIdentity = CKDiscoverAllUserIdentitiesOperation()
        var discoveredIds: [CKUserIdentity] = []
        discoverIdentity.userIdentityDiscoveredBlock = { identity in
            discoveredIds.append(identity)
        }
        discoverIdentity.discoverAllUserIdentitiesCompletionBlock = { error in
            completion(discoveredIds, error)
        }
        
        CKContainer.default().add(discoverIdentity)
    }
    
    func fetchUserIdentityWith(email: String, completion: @escaping (CKUserIdentity?, Error?) -> Void) {
        CKContainer.default().discoverUserIdentity(withEmailAddress: email, completionHandler: completion)
    }
}
