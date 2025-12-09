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

    // MARK: - User Profile and Relationships

    // Function to fetch a single user profile, handling the new friends/requests arrays
    func fetchUserProfile(uid: String, completion: @escaping (Result<UserProfile, Error>) -> Void) {
        userDocRef(uid: uid).getDocument { snapshot, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let data = snapshot?.data(), let uid = snapshot?.documentID else {
                let error = NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "User profile data not found."])
                completion(.failure(error))
                return
            }

            // Create UserProfile instance, safely defaulting new fields to []
            let profile = UserProfile(
                uid: uid,
                displayName: data["displayName"] as? String ?? "N/A",
                username: data["username"] as? String ?? "N/A",
                region: data["region"] as? String ?? "N/A",
                currentEmoji: data["currentEmoji"] as? String ?? "🙂",
                photoURL: data["photoURL"] as? String,
                friends: data["friends"] as? [String] ?? [],
                incomingRequests: data["incomingRequests"] as? [String] ?? []
            )
            completion(.success(profile))
        }
    }
    
    // Function to fetch multiple user profiles (used for displaying friends/requests)
    func fetchUserProfiles(uids: [String], completion: @escaping (Result<[UserProfile], Error>) -> Void) {
        guard !uids.isEmpty else {
            completion(.success([]))
            return
        }

        // Firestore query to get multiple documents by ID
        db.collection("users").whereField(FieldPath.documentID(), in: uids).getDocuments { snapshot, error in
             if let error = error {
                completion(.failure(error))
                return
            }

            let profiles: [UserProfile] = snapshot?.documents.compactMap { doc -> UserProfile? in
                let data = doc.data()
                let uid = doc.documentID
                
                return UserProfile(
                    uid: uid,
                    displayName: data["displayName"] as? String ?? "N/A",
                    username: data["username"] as? String ?? "N/A",
                    region: data["region"] as? String ?? "N/A",
                    currentEmoji: data["currentEmoji"] as? String ?? "🙂",
                    photoURL: data["photoURL"] as? String,
                    friends: data["friends"] as? [String] ?? [],
                    incomingRequests: data["incomingRequests"] as? [String] ?? []
                )
            } ?? []
            completion(.success(profiles))
        }
    }


    // Function to search users by username prefix
    func searchUsers(query: String, completion: @escaping ([UserProfile]?, Error?) -> Void) {
        let lowercasedQuery = query.lowercased()
        // Range query for prefix matching
        let endQuery = lowercasedQuery + "\u{f8ff}"
        
        db.collection("users")
            .whereField("username", isGreaterThanOrEqualTo: lowercasedQuery)
            .whereField("username", isLessThan: endQuery)
            .limit(to: 50)
            .getDocuments { snapshot, error in
                if let error = error {
                    completion(nil, error)
                    return
                }
                
                let results: [UserProfile] = snapshot?.documents.compactMap { doc -> UserProfile? in
                    let data = doc.data()
                    let uid = doc.documentID
                    
                    return UserProfile(
                        uid: uid,
                        displayName: data["displayName"] as? String ?? "N/A",
                        username: data["username"] as? String ?? "N/A",
                        region: data["region"] as? String ?? "N/A",
                        currentEmoji: data["currentEmoji"] as? String ?? "🙂",
                        photoURL: data["photoURL"] as? String,
                        friends: data["friends"] as? [String] ?? [],
                        incomingRequests: data["incomingRequests"] as? [String] ?? []
                    )
                } ?? []
                completion(results, nil)
            }
    }

    // Function to handle sending a friend request (updates target user's incomingRequests array)
    func addIncomingRequest(targetUID: String, senderUID: String, completion: @escaping (Error?) -> Void) {
            let targetRef = db.collection("users").document(targetUID)
            
            targetRef.updateData([
                "incomingRequests": FieldValue.arrayUnion([senderUID])
            ]) { error in
                
                // MARK: Place holder for notification I think
                completion(error)
            }
        }

    //Completes a friend request by adding the reciprocal friendship connectiona nd clearing the pending request status for both users using a Write Batch.
    // In FirebaseService.swift

    func acceptFriendRequestAtomic(requesterUID A_UID: String, acceptorUID B_UID: String, completion: @escaping (Error?) -> Void) {
        let batch = db.batch()
        let acceptorDocRef = userDocRef(uid: B_UID) // Current User (Acceptor)
        let requesterDocRef = userDocRef(uid: A_UID) // Request Sender (Requester)
        // Action: Remove A from 'incomingRequests', Add A to 'friends'
        batch.updateData([
            "incomingRequests": FieldValue.arrayRemove([A_UID]),
            "friends": FieldValue.arrayUnion([A_UID])
        ], forDocument: acceptorDocRef)
        // Action: Add B to 'friends'.
        batch.updateData([
            "friends": FieldValue.arrayUnion([B_UID])
        ], forDocument: requesterDocRef)
        // The batch ensures both updates succeed or both fail.
        batch.commit { error in
            if let error = error {
                completion(error)
                return
            }
            
            // MARK: - PLACE FOR NOTIFICATION LOGIC 
            // For now, simply complete the friend request logic:
            completion(nil)
        }
    }
    // Atomically removes the friendship connection from both users using a Write Batch.
    func removeFriendAtomic(userUID_1: String, userUID_2: String, completion: @escaping (Error?) -> Void) {
        let batch = db.batch()
        
        // Update User 1's Document
        let docRef_1 = userDocRef(uid: userUID_1)
        batch.updateData([
            "friends": FieldValue.arrayRemove([userUID_2]) // Remove User 2 from User 1's friends
        ], forDocument: docRef_1)
        
        // Update User 2's Document
        let docRef_2 = userDocRef(uid: userUID_2)
        batch.updateData([
            "friends": FieldValue.arrayRemove([userUID_1]) // Remove User 1 from User 2's friends
        ], forDocument: docRef_2)
        
        // Commit the Batch
        batch.commit(completion: completion)
    }

    
    // Generic function to update the user's entire profile data (used for accepting/removing friends)
    func updateProfile(userProfile: UserProfile, completion: @escaping (Error?) -> Void) {
        do {
            // Using a Codable-based encoder to safely convert the struct back to a dictionary
            let data = try Firestore.Encoder().encode(userProfile)
            userDocRef(uid: userProfile.uid).setData(data, merge: true) { error in
                completion(error)
            }
        } catch {
            completion(error)
        }
    }
}
