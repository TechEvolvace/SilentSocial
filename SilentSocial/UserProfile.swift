//  Project: SilentSocial
//  Names: Phuc Dinh, Nicholas Ng, Preston Tu, Rui Xue
//  Course: CS329E
//  UserProfile.swift

import Foundation

struct UserProfile: Codable {
    var uid: String
    var displayName: String
    var username: String    // no @ stored in DB; prepend @ in UI
    var region: String
    var currentEmoji: String
    var photoURL: String?   // HTTPS string from Firebase Storage, optional
    var friends: [String] = []          // Stores UIDs of accepted friends
    var incomingRequests: [String] = [] // Stores UIDs of users who sent requests

    // Default for new users (so Profile screen won’t crash)
    static func empty(uid: String) -> UserProfile {
        return UserProfile(uid: uid,
                           displayName: "New User",
                           username: "newuser",
                           region: "US",
                           currentEmoji: "🙂",
                           photoURL: nil)
    }
}
