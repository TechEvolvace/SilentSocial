// Project: SilentSocial
// Names: Phuc Dinh, Nicholas Ng, Preston Tu, Rui Xue
// Course: CS329E
// DashboardViewController.swift
// SilentSocial

import UIKit

class DashboardViewController: UIViewController {
    
    // MARK: - Outlets
    @IBOutlet weak var welcomeLabel: UILabel!
    @IBOutlet weak var notificationButton: UIButton!
    @IBOutlet weak var settingsButton: UIButton!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var badgeLabel: UILabel!
    @IBOutlet weak var notificationTableView: UITableView!
    @IBOutlet weak var notificationContainerView: UIView!
    
    // MARK: - Properties
    var notifications: [NotificationItem] = []
    var isNotificationMenuVisible = false
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupNotificationTableView()
        loadInitialNotifications()
        updateBadgeCount()
    }
    
    // MARK: - Setup
    private func setupUI() {
        view.backgroundColor = .white
        
        // Welcome label
        welcomeLabel.text = "Welcome!"
        welcomeLabel.font = UIFont.systemFont(ofSize: 32, weight: .semibold)
        welcomeLabel.textColor = UIColor(hex: "#2C3331")
        
        // Message label
        messageLabel.text = "Start your journey with SilentSocial!"
        messageLabel.font = UIFont.systemFont(ofSize: 18, weight: .regular)
        messageLabel.textColor = UIColor(hex: "#2C3331")
        messageLabel.textAlignment = .center
        messageLabel.numberOfLines = 0
        
        // Notification container styling
        notificationContainerView.isHidden = true
        notificationContainerView.backgroundColor = .white
        notificationContainerView.layer.cornerRadius = 8
        notificationContainerView.layer.shadowColor = UIColor.black.cgColor
        notificationContainerView.layer.shadowOpacity = 0.15
        notificationContainerView.layer.shadowOffset = CGSize(width: 0, height: 3)
        notificationContainerView.layer.shadowRadius = 6
        
        // Badge label styling
        badgeLabel.isHidden = true
        badgeLabel.backgroundColor = UIColor(hex: "#275A7")
        badgeLabel.textColor = .white
        badgeLabel.font = UIFont.systemFont(ofSize: 12, weight: .bold)
        badgeLabel.layer.cornerRadius = 10
        badgeLabel.clipsToBounds = true
        badgeLabel.textAlignment = .center
        
        // Button tints
        notificationButton.tintColor = UIColor(hex: "#275A7")
        settingsButton.tintColor = UIColor(hex: "#2C3331")
        
        // Tap gesture to dismiss dropdown
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTapOutside(_:)))
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)
    }
    
    private func setupNotificationTableView() {
        notificationTableView.delegate = self
        notificationTableView.dataSource = self
        notificationTableView.register(NotificationCell.self, forCellReuseIdentifier: "NotificationCell")
        notificationTableView.separatorStyle = .singleLine
        notificationTableView.backgroundColor = .white
        notificationTableView.rowHeight = UITableView.automaticDimension
        notificationTableView.estimatedRowHeight = 60
    }
    
    private func loadInitialNotifications() {
        let welcomeNotification = NotificationItem(
            id: UUID().uuidString,
            message: "Welcome to SilentSocial!",
            timestamp: Date(),
            isRead: false
        )
        notifications.insert(welcomeNotification, at: 0)
    }
    
    // MARK: - Actions
    @IBAction func notificationButtonTapped(_ sender: UIButton) {
        isNotificationMenuVisible.toggle()
        UIView.animate(withDuration: 0.3) {
            self.notificationContainerView.isHidden = !self.isNotificationMenuVisible
        }
        notificationTableView.reloadData()
    }
    
    @IBAction func settingsButtonTapped(_ sender: UIButton) {
        // Placeholder - gear icon doesn't do anything yet
        print("Settings button tapped - to be implemented")
    }
    
    @objc private func handleTapOutside(_ gesture: UITapGestureRecognizer) {
        let location = gesture.location(in: view)
        let buttonFrame = view.convert(notificationButton.frame, from: notificationButton.superview)
        let containerFrame = view.convert(notificationContainerView.frame, from: notificationContainerView.superview)
        
        if !containerFrame.contains(location) &&
           !buttonFrame.contains(location) &&
           isNotificationMenuVisible {
            isNotificationMenuVisible = false
            UIView.animate(withDuration: 0.3) {
                self.notificationContainerView.isHidden = true
            }
        }
    }
    
    // MARK: - Notification Management
    private func updateBadgeCount() {
        let unreadCount = notifications.filter { !$0.isRead }.count
        if unreadCount > 0 {
            badgeLabel.isHidden = false
            badgeLabel.text = "\(unreadCount)"
        } else {
            badgeLabel.isHidden = true
        }
    }
    
    private func markNotificationAsRead(at index: Int) {
        notifications[index].isRead = true
        updateBadgeCount()
        notificationTableView.reloadRows(at: [IndexPath(row: index, section: 0)], with: .automatic)
    }
}

// MARK: - TableView
extension DashboardViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return notifications.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "NotificationCell", for: indexPath) as! NotificationCell
        let notification = notifications[indexPath.row]
        cell.configure(with: notification)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        markNotificationAsRead(at: indexPath.row)
    }
}

// MARK: - Color Extension
extension UIColor {
    convenience init(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
        
        var rgb: UInt64 = 0
        Scanner(string: hexSanitized).scanHexInt64(&rgb)
        
        let red = CGFloat((rgb & 0xFF0000) >> 16) / 255.0
        let green = CGFloat((rgb & 0x00FF00) >> 8) / 255.0
        let blue = CGFloat(rgb & 0x0000FF) / 255.0
        
        self.init(red: red, green: green, blue: blue, alpha: 1.0)
    }
}
