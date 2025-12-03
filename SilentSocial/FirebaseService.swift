//  Project: SilentSocial
//  Names: Phuc Dinh, Nicholas Ng, Preston Tu, Rui Xue
//  Course: CS329E
//  FirebaseService.swift

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

    func storagePostImageRef(uid: String, postID: String) -> StorageReference {
        return storage.reference().child("posts/\(uid)/\(postID).jpg")
    }

    func postsCollection() -> CollectionReference {
        return db.collection("posts")
    }

    func userPostsCollection(uid: String) -> CollectionReference {
        return db.collection("users").document(uid).collection("posts")
    }
}
