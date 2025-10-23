//
//  FirebaseService.swift
//  SilentSocial
//
//  Created by Preston Tu on 10/20/25.
//
import Foundation
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage

final class FirebaseService {
    static let shared = FirebaseService()

    let db = Firestore.firestore()
    let storage = Storage.storage()

    private init() {}

    func currentUID() -> String? {
        return Auth.auth().currentUser?.uid
    }

    func userDocRef(uid: String) -> DocumentReference {
        return db.collection("users").document(uid)
    }

    func storageProfileImageRef(uid: String) -> StorageReference {
        return storage.reference().child("users/\(uid)/avatar.jpg")
    }
}
