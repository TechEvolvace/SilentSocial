// Project: SilentSocial
// Names: Phuc Dinh, Nicholas Ng, Preston Tu, Rui Xue
// Course: CS329E
// FriendListViewController.swift

import UIKit
import FirebaseAuth
import FirebaseFirestore

class FriendListViewController: UIViewController, UITextFieldDelegate {
    
    // Outlets
    @IBOutlet weak var segmentedControl: UISegmentedControl!
    @IBOutlet weak var friendsTableView: UITableView!
    @IBOutlet weak var requestsTableView: UITableView!
    @IBOutlet weak var searchResultsTableView: UITableView!
    
    // Data Properties
    private var currentUserProfile: UserProfile?
    private var friendsArray: [UserProfile] = []
    private var requestsArray: [UserProfile] = []
    private var searchResultsArray: [UserProfile] = []
    private var FriendCellReuseIdentifier = "FriendCell"

    // Manual Search Bar
    private let searchTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "Search users by username"
        textField.borderStyle = .roundedRect // Gives it a standard search bar look
        textField.autocapitalizationType = .none
        textField.autocorrectionType = .no
        textField.returnKeyType = .search // Only search when user taps 'Search'
        textField.translatesAutoresizingMaskIntoConstraints = false // Must be false for auto-layout
        return textField
    }()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Connections"
        navigationController?.setNavigationBarHidden(false, animated: false)
        navigationItem.hidesSearchBarWhenScrolling = false
        setupSegmentedControl()
        setupTableViews()
        setupManualSearchBar()
        // Initial load of data
        loadAllRelationshipData()
    }
    
    // MARK: - Setup
    private func setupSegmentedControl() {
        // Ensure only two segments exist before inserting the third
        if segmentedControl.numberOfSegments < 3 {
            segmentedControl.setTitle("Friends", forSegmentAt: 0)
            segmentedControl.setTitle("Requests", forSegmentAt: 1)
            segmentedControl.insertSegment(withTitle: "Search", at: 2, animated: false)
        }
        segmentedControl.selectedSegmentIndex = 0
        segmentedControlChanged(segmentedControl)
    }
    
    private func setupTableViews() {
        // Register the custom FriendCell class
        friendsTableView.register(FriendCell.self, forCellReuseIdentifier: FriendCellReuseIdentifier)
        requestsTableView.register(FriendCell.self, forCellReuseIdentifier: FriendCellReuseIdentifier)
        searchResultsTableView.register(FriendCell.self, forCellReuseIdentifier: FriendCellReuseIdentifier)
        
        friendsTableView.dataSource = self
        friendsTableView.delegate = self
        requestsTableView.dataSource = self
        requestsTableView.delegate = self
        searchResultsTableView.dataSource = self
        searchResultsTableView.delegate = self
        
        friendsTableView.tableFooterView = UIView()
        requestsTableView.tableFooterView = UIView()
        searchResultsTableView.tableFooterView = UIView()
    }
    
    // Place the search bar in the view below the segmented control
    private func setupManualSearchBar() {
        view.addSubview(searchTextField)
        searchTextField.delegate = self
        
        // Setup Constraints: Place the search text field right below the segmented control
        let safeArea = view.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            searchTextField.topAnchor.constraint(equalTo: segmentedControl.bottomAnchor, constant: 8),
            searchTextField.leadingAnchor.constraint(equalTo: safeArea.leadingAnchor, constant: 16),
            searchTextField.trailingAnchor.constraint(equalTo: safeArea.trailingAnchor, constant: -16),
            searchTextField.heightAnchor.constraint(equalToConstant: 40)
        ])
        
        // Hide it by default
        searchTextField.isHidden = true
        
        searchResultsTableView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            // This is the key change: Anchor the table view's top to the search field's bottom
            searchResultsTableView.topAnchor.constraint(equalTo: searchTextField.bottomAnchor, constant:8),
            // Ensure the other constraints are set for the table view
            searchResultsTableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            searchResultsTableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            searchResultsTableView.bottomAnchor.constraint(equalTo: safeArea.bottomAnchor)
        ])
    }
    
    // MARK: - Data Loading
    
    private func loadAllRelationshipData() {
        guard let currentUID = FirebaseService.shared.currentUID() else {
            return
        }
        
        // Fetch current user's profile to get friends and request lists
        FirebaseService.shared.fetchUserProfile(uid: currentUID) { [weak self] result in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                switch result {
                case .success(let userProfile):
                    self.currentUserProfile = userProfile
                    
                    // Fetch and display Friends (UIDs are stored in profile.friends)
                    self.fetchAndDisplayUsers(uids: userProfile.friends, for: self.friendsTableView) { profiles in
                        self.friendsArray = profiles
                    }
                    
                    // Fetch and display Requests (UIDs are stored in profile.incomingRequests)
                    self.fetchAndDisplayUsers(uids: userProfile.incomingRequests, for: self.requestsTableView) { profiles in
                        self.requestsArray = profiles
                    }
                    
                case .failure(let error):
                    print("Error fetching user relationships: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func fetchAndDisplayUsers(uids: [String], for tableView: UITableView, completion: @escaping ([UserProfile]) -> Void) {
        guard !uids.isEmpty else {
            completion([])
            DispatchQueue.main.async { tableView.reloadData() }
            return
        }
        
        FirebaseService.shared.fetchUserProfiles(uids: uids) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let profiles):
                    completion(profiles)
                    tableView.reloadData()
                case .failure(let error):
                    print("Error fetching detailed profiles: \(error.localizedDescription)")
                    completion([])
                    tableView.reloadData()
                }
            }
        }
    }
    
    private func searchFriends(query: String) {
        FirebaseService.shared.searchUsers(query: query) { [weak self] users, error in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                if let users = users {
                    // Filter out the current user and users already on the friends or requests list
                    let myUID = FirebaseService.shared.currentUID()
                    let existingFriendsAndRequests = Set(self.friendsArray.map { $0.uid } + self.requestsArray.map { $0.uid })
                    
                    self.searchResultsArray = users.filter {
                        $0.uid != myUID && !existingFriendsAndRequests.contains($0.uid)
                    }
                    self.searchResultsTableView.reloadData()
                } else if let error = error {
                    print("Search Error: \(error.localizedDescription)")
                }
            }
        }
    }
    
    // MARK: - Actions
    
    @IBAction func segmentedControlChanged(_ sender: UISegmentedControl) {
        let selectedIndex = sender.selectedSegmentIndex
        
        // Manage Table View Visibility
        friendsTableView.isHidden = selectedIndex != 0
        requestsTableView.isHidden = selectedIndex != 1
        searchResultsTableView.isHidden = selectedIndex != 2
        
        // Control visibility of the manual search bar
        searchTextField.isHidden = selectedIndex != 2
        
        // Control Keyboard and Focus
        if selectedIndex == 2 { // Search segment is selected
            // Clear the search bar and results on entry
            if searchTextField.text?.isEmpty ?? true {
                searchResultsArray = []
                searchResultsTableView.reloadData()
            }
            // Immediately focus the search bar
            DispatchQueue.main.async {
                self.searchTextField.becomeFirstResponder()
            }
            
            // Restore navigation bar title (no longer managing titleView)
            self.navigationItem.title = "Connections"
            
        } else {
            // When switching away, hide the keyboard
            self.searchTextField.resignFirstResponder()
            self.navigationItem.title = "Connections"
        }
        
        self.view.layoutIfNeeded() // Force layout update
    }
    
    // MARK: - Helper (Assuming this helper exists in a base class or extension)
    private func showInfo(_ title: String, _ message: String) {
        DispatchQueue.main.async {
            let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            self.present(alert, animated: true)
        }
    }
}

// MARK: - UITableViewDataSource
extension FriendListViewController: UITableViewDataSource {
    
    // Corrected protocol method name from 'tableView(_:numberOfRowsInSectionAt:)' to 'tableView(_:numberOfRowsInSection:)'
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView == friendsTableView {
            return friendsArray.count
        } else if tableView == requestsTableView {
            return requestsArray.count
        } else { // searchResultsTableView
            return searchResultsArray.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // To custom Friend Cell
        guard let cell = tableView.dequeueReusableCell(withIdentifier: FriendCellReuseIdentifier, for: indexPath) as? FriendCell else {
            return UITableViewCell()
        }
        
        let user: UserProfile
        let actionType: FriendCell.ActionType
        
        if tableView == friendsTableView {
            user = friendsArray[indexPath.row]
            actionType = .friend
            // Set the action handler to call the remove logic
            cell.actionHandler = { [weak self] profile in
                self?.handleRemoveFriend(for: profile)
            }
        } else if tableView == requestsTableView {
            // FIX 2: Set user and actionType correctly
            user = requestsArray[indexPath.row]
            actionType = .request
            
            // Set the action handler to call the accept request logic
            cell.actionHandler = { [weak self] senderProfile in
                self?.handleAcceptRequest(for: senderProfile)
            }
        } else { // searchResultsTableView
            user = searchResultsArray[indexPath.row]
            actionType = .search
            // Set the action handler to call the send request logic
            cell.actionHandler = { [weak self] profile in
                self?.handleSendFriendRequest(to: profile)
            }
        }
        
        // Final call to configure the cell now that user and actionType are set
        cell.configure(with: user, type: actionType)
        return cell
    }
}

// MARK: - UITextFieldDelegate (Manual Search Logic)
extension FriendListViewController {
    
    // Called when the user presses 'Return' or 'Search' on the keyboard
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder() // Dismiss the keyboard
        
        guard let searchText = textField.text?.lowercased(),
              !searchText.isEmpty
        else {
            // Clear results if search bar is empty
            self.searchResultsArray = []
            self.searchResultsTableView.reloadData()
            return true
        }
        
        // Trigger the search if the query is 2 or more characters long
        if searchText.count >= 2 {
            searchFriends(query: searchText)
        } else {
            // Clear results for short queries
            self.searchResultsArray = []
            self.searchResultsTableView.reloadData()
        }
        
        return true
    }
}


// MARK: - UITableViewDelegate
extension FriendListViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // The actions (Accept, Remove, Send Request) are handled by the button in the FriendCell,
        // so we only deselect the row here.
        tableView.deselectRow(at: indexPath, animated: true)
        
        // MARK: Add navigation to a detailed profile view here if done
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
}

// MARK: - Friend Action Handlers Database Updater
extension FriendListViewController {
    
    // Implements a pre-check to prevent duplicate pending friend requests
    private func handleSendFriendRequest(to targetUser: UserProfile) {
        guard let myUID = FirebaseService.shared.currentUID() else { return }
        
        // Fetch the target user's profile to check for an existing pending request
        FirebaseService.shared.fetchUserProfile(uid: targetUser.uid) { [weak self] result in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                switch result {
                case .success(let targetProfile):
                    
                    // CHECK: Is my UID already in their incomingRequests list?
                    if targetProfile.incomingRequests.contains(myUID) {
                        // Request is already pending. Show pop-up and stop.
                        self.showInfo("Pending Request", "You already sent a pending friend request to @\(targetProfile.username).")
                        return // Stop execution here
                    }
                    
                    // If not pending, proceed to send the request (write)
                    // Update the target user's profile by adding my UID to their incomingRequests array
                    FirebaseService.shared.addIncomingRequest(targetUID: targetUser.uid, senderUID: myUID) { [weak self] error in
                        DispatchQueue.main.async {
                            if let error = error {
                                print("Error sending request: \(error.localizedDescription)")
                                self?.showInfo("Error", "Could not send request: \(error.localizedDescription)")
                            } else {
                                self?.showInfo("Success", "Friend request sent to @\(targetUser.username).")
                                // Remove the user from the search results once the request is sent
                                self?.searchResultsArray.removeAll { $0.uid == targetUser.uid }
                                self?.searchResultsTableView.reloadData()
                                // Reload my profile to refresh friend/request status
                                self?.loadAllRelationshipData()
                            }
                        }
                    }
                    
                case .failure(let error):
                    print("Error fetching target user profile before sending request: \(error.localizedDescription)")
                    self.showInfo("Error", "Could not verify target user status.")
                }
            }
        }
    }
    
    // Uses the new atomic batch function to ensure reciprocal friendship
    private func handleAcceptRequest(for targetUser: UserProfile) {
        guard let myUID = FirebaseService.shared.currentUID() else { return }
        
        // targetUser is the A_UID (Requester), myUID is the B_UID (Acceptor)
        FirebaseService.shared.acceptFriendRequestAtomic(requesterUID: targetUser.uid, acceptorUID: myUID) { [weak self] error in
            DispatchQueue.main.async { // Ensure UI updates happen on the main thread
                if let error = error {
                    print("Error accepting request: \(error.localizedDescription)")
                    self?.showInfo("Error", "Could not accept request: \(error.localizedDescription)")
                } else {
                    self?.showInfo("Success", "You are now friends with @\(targetUser.username)!")
                    // Reload all data to refresh friends/requests segments, handling UI cleanup for both users
                    self?.loadAllRelationshipData()
                }
            }
        }
    }
    
    // Uses the atomic batch function to remove the friendship from both users simultaneously.
    private func handleRemoveFriend(for targetUser: UserProfile) {
        guard let myUID = FirebaseService.shared.currentUID() else { return }
        
        FirebaseService.shared.removeFriendAtomic(userUID_1: myUID, userUID_2: targetUser.uid) { [weak self] error in
            DispatchQueue.main.async {
                if let error = error {
                    print("Error removing friend: \(error.localizedDescription)")
                    self?.showInfo("Error", "Could not remove friend: \(error.localizedDescription)")
                } else {
                    self?.showInfo("Success", "You are no longer friends with @\(targetUser.username).")
                    // Reload all data to refresh friend segments
                    self?.loadAllRelationshipData()
                }
            }
        }
    }
}
