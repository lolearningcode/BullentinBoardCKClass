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
    
    func createMessage(text: String, timestamp: Date) {
        let message = Message(text: text, timestamp: timestamp)
        self.saveMessage(message: message) { (_) in
            
        }
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
            let messages = records.compactMap({Message(ckRecord: $0)})
            self.messages = messages
            completion(true)
        }
    }
}
