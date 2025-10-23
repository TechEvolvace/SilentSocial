// Project: SilentSocial
// Names: Phuc Dinh, Nicholas Ng, Preston Tu, Rui Xue
// Course: CS329E
// NotificationItem.swift
// SilentSocial

import Foundation

struct NotificationItem {
    let id: String
    let message: String
    let timestamp: Date
    var isRead: Bool
    
    var formattedTimestamp: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: timestamp, relativeTo: Date())
    }
}
