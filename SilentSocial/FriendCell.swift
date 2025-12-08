//  Project: SilentSocial
//  Names: Phuc Dinh, Nicholas Ng, Preston Tu, Rui Xue
//  Course: CS329E
//  FriendCell.swift

import UIKit

final class FriendCell: UITableViewCell {
    
    // Closure to handle the button press, passing the user profile back to the ViewController
    var actionHandler: ((UserProfile) -> Void)?
    
    private var userProfile: UserProfile!
    
    // MARK: - UI Components
    
    private let avatarImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.layer.cornerRadius = 20 // Half of 40x40
        iv.backgroundColor = .systemGray4
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()
    
    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .semibold)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let usernameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14, weight: .regular)
        label.textColor = .systemGray
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let actionButton: UIButton = {
        let button = UIButton(type: .system)
        button.titleLabel?.font = .systemFont(ofSize: 14, weight: .medium)
        button.layer.cornerRadius = 8
        button.clipsToBounds = true
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    // MARK: - Initialization
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViews() {
        contentView.addSubview(avatarImageView)
        contentView.addSubview(nameLabel)
        contentView.addSubview(usernameLabel)
        contentView.addSubview(actionButton)
        
        actionButton.addTarget(self, action: #selector(actionButtonTapped), for: .touchUpInside)
        
        let padding: CGFloat = 12
        
        NSLayoutConstraint.activate([
            // Avatar
            avatarImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: padding),
            avatarImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            avatarImageView.widthAnchor.constraint(equalToConstant: 40),
            avatarImageView.heightAnchor.constraint(equalToConstant: 40),
            
            // Action Button
            actionButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -padding),
            actionButton.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            actionButton.widthAnchor.constraint(equalToConstant: 100),
            actionButton.heightAnchor.constraint(equalToConstant: 30),
            
            // Name Label
            nameLabel.leadingAnchor.constraint(equalTo: avatarImageView.trailingAnchor, constant: padding),
            nameLabel.trailingAnchor.constraint(equalTo: actionButton.leadingAnchor, constant: -padding),
            nameLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            
            // Username Label
            usernameLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            usernameLabel.trailingAnchor.constraint(equalTo: nameLabel.trailingAnchor),
            usernameLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 2),
            usernameLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8)
        ])
    }
    
    // MARK: - Configuration
    
    enum ActionType {
        case friend
        case request
        case search
        case none
    }
    
    func configure(with profile: UserProfile, type: ActionType) {
        self.userProfile = profile
        nameLabel.text = profile.displayName
        usernameLabel.text = "@" + profile.username
        
        // Reset image
        avatarImageView.image = nil
        
        // Set button appearance based on type
        switch type {
        case .friend:
            actionButton.setTitle("Remove", for: .normal)
            actionButton.backgroundColor = .systemRed
            actionButton.setTitleColor(.white, for: .normal)
            actionButton.isHidden = false
        case .request:
            actionButton.setTitle("Accept", for: .normal)
            actionButton.backgroundColor = .systemGreen
            actionButton.setTitleColor(.white, for: .normal)
            actionButton.isHidden = false
        case .search:
            actionButton.setTitle("Send Request", for: .normal)
            actionButton.backgroundColor = .systemBlue
            actionButton.setTitleColor(.white, for: .normal)
            actionButton.isHidden = false
        case .none:
            actionButton.isHidden = true
        }
        
        // Load Avatar (Simplified Logic for example)
        if let urlString = profile.photoURL, let url = URL(string: urlString) {
            // NOTE: Use a production image loader (Kingfisher, SDWebImage) for caching.
            URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
                if let data = data, let image = UIImage(data: data) {
                    DispatchQueue.main.async {
                        self?.avatarImageView.image = image
                    }
                }
            }.resume()
        } else {
            // Default image if none is set
            avatarImageView.image = UIImage(systemName: "person.circle.fill")
            avatarImageView.tintColor = .systemGray
        }
    }
    
    @objc private func actionButtonTapped() {
        // Triggers the closure defined in the View Controller
        actionHandler?(userProfile)
    }
}
