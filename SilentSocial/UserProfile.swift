//
//  UserProfile.swift
//  SilentSocial
//
//  Created by Preston Tu on 10/20/25.
//
import Foundation

struct UserProfile: Codable {
    var uid: String
    var displayName: String
    var username: String    // no @ stored in DB; prepend @ in UI
    var region: String
    var currentEmoji: String
    var photoURL: String?   // HTTPS string from Firebase Storage, optional

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
