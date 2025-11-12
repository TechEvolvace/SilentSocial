// Project: SilentSocial
// Names: Phuc Dinh, Nicholas Ng, Preston Tu, Rui Xue
// Course: CS329E
// NotificationCell.swift

import UIKit

class NotificationCell: UITableViewCell {
    
    private let messageLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        label.textColor = UIColor(hex: "#2C3331")
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let timeLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 12, weight: .regular)
        label.textColor = .lightGray
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let unreadIndicator: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(hex: "#275A7")
        view.layer.cornerRadius = 4
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupViews()
    }
    
    private func setupViews() {
        contentView.backgroundColor = .white
        contentView.addSubview(unreadIndicator)
        contentView.addSubview(messageLabel)
        contentView.addSubview(timeLabel)
        
        NSLayoutConstraint.activate([
            unreadIndicator.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 12),
            unreadIndicator.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            unreadIndicator.widthAnchor.constraint(equalToConstant: 8),
            unreadIndicator.heightAnchor.constraint(equalToConstant: 8),
            
            messageLabel.leadingAnchor.constraint(equalTo: unreadIndicator.trailingAnchor, constant: 12),
            messageLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -12),
            messageLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            
            timeLabel.leadingAnchor.constraint(equalTo: messageLabel.leadingAnchor),
            timeLabel.topAnchor.constraint(equalTo: messageLabel.bottomAnchor, constant: 4),
            timeLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12)
        ])
    }
    
    func configure(with notification: NotificationItem) {
        messageLabel.text = notification.message
        timeLabel.text = notification.formattedTimestamp
        unreadIndicator.isHidden = notification.isRead
        
        if !notification.isRead {
            messageLabel.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        } else {
            messageLabel.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        }
    }
}
