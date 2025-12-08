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
    func addIncomingRequest(targetUID: String, senderProfile: UserProfile, completion: @escaping (Error?) -> Void) {
        let targetRef = userDocRef(uid: targetUID) // Using existing helper
        
        // Update the recipient's incomingRequests array
        targetRef.updateData([
            "incomingRequests": FieldValue.arrayUnion([senderProfile.uid])
        ]) { error in
            if let error = error {
                completion(error)
                return
            }
            
            // PLACEHOLDER FOR NOTIFICATION - I DON"T KNOW HOW TO DO THIS
            // self.logNotification(for: targetUID, message: "@\(senderProfile.username) sent you a friend request!") { _ in
            //     completion(nil)
            // }
            completion(nil) // Proceed without logging the notification for now
        }
    }
    
    // Function to handle accepting a friend request
    func acceptFriendRequest(myProfile: UserProfile, senderProfile: UserProfile, completion: @escaping (Error?) -> Void) {
        let myUID = myProfile.uid
        let senderUID = senderProfile.uid
        
        // Update MY profile: add sender to friends, remove from incomingRequests
        var myNewProfile = myProfile
        if !myNewProfile.friends.contains(senderUID) {
            myNewProfile.friends.append(senderUID)
        }
        myNewProfile.incomingRequests.removeAll { $0 == senderUID }
        
        self.updateProfile(userProfile: myNewProfile) { [weak self] error in
            guard let self = self else { completion(nil); return } // Safety check
            if let error = error { completion(error); return }
            
            // Update SENDER's profile (add me to their friends list)
            self.fetchUserProfile(uid: senderUID) { result in
                switch result {
                case .success(var senderNewProfile):
                    if !senderNewProfile.friends.contains(myUID) {
                        senderNewProfile.friends.append(myUID)
                    }
                    
                    self.updateProfile(userProfile: senderNewProfile) { error in
                        if let error = error { completion(error); return }
                        
                        // PLACEHOLDER FOR NOTIFICATION  - I DON"T KNOW HOW TO DO THIS
                        // let message = "@\(myProfile.username) accepted your friend request!"
                        // self.logNotification(for: senderUID, message: message) { _ in
                        //     completion(nil)
                        // }
                        completion(nil) // Proceed without logging the notification for now
                    }
                case .failure(let error):
                    completion(error)
                }
            }
        }
    }
    
    // Generic function to update the user's entire profile data (used for accepting/removing friends)
    func updateProfile(userProfile: UserProfile, completion: @escaping (Error?) -> Void) {
        do {
            // Using a Codable-based encoder to safely convert the struct back to a dictionary
            let data = try Firestore.Encoder().encode(userProfile)
            userDocRef(uid: userProfile.uid).setData(data) { error in
                completion(error)
            }
        } catch {
            completion(error)
        }
    }
}
