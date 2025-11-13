// Project: SilentSocial
// Names: Phuc Dinh, Nicholas Ng, Preston Tu, Rui Xue
// Course: CS329E
// DashboardViewController.swift

import UIKit

class DashboardViewController: UIViewController {
    
    // MARK: - Outlets (existing)
    @IBOutlet weak var welcomeLabel: UILabel!
    @IBOutlet weak var notificationButton: UIButton!
    @IBOutlet weak var settingsButton: UIButton!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var badgeLabel: UILabel!
    @IBOutlet weak var notificationTableView: UITableView!
    @IBOutlet weak var notificationContainerView: UIView!
    
    // MARK: - Properties (existing)
    var notifications: [NotificationItem] = []
    var isNotificationMenuVisible = false
    private var selectedImage: UIImage?     // Phuc's NEW changes
    
    // MARK: - New UI: Containers & Collections
    private let contentScrollView = UIScrollView()
    private let contentStack = UIStackView()
    
    // Gallery header: title + "+"
    private let galleryTitleLabel: UILabel = {
        let l = UILabel()
        l.text = "Gallery"
        l.font = .systemFont(ofSize: 22, weight: .semibold)
        l.textColor = .label
        return l
    }()
    private lazy var addToGalleryButton: UIButton = {
        let b = UIButton(type: .system)
        b.setImage(UIImage(systemName: "plus"), for: .normal)
        b.tintColor = UIColor(hex: "#2C3331")
        b.backgroundColor = .white
        b.layer.cornerRadius = 22
        b.layer.borderWidth = 2
        b.layer.borderColor = UIColor(hex: "#2C3331").cgColor
        b.widthAnchor.constraint(equalToConstant: 44).isActive = true
        b.heightAnchor.constraint(equalToConstant: 44).isActive = true
        b.addTarget(self, action: #selector(addPostTapped), for: .touchUpInside)
        b.accessibilityLabel = "Add Post"
        return b
    }()
    private var galleryCollectionView: UICollectionView!
    
    private let emojiTitleLabel = DashboardViewController.makeSectionTitle("Emoji")
    private var emojiCollectionView: UICollectionView!
    
    private let imagesTitleLabel = DashboardViewController.makeSectionTitle("Images")
    private var imagesCollectionView: UICollectionView!
    
    private let sketchesTitleLabel = DashboardViewController.makeSectionTitle("Sketches")
    private var sketchesCollectionView: UICollectionView!
    
    // Post header: title + "+"
    private let postsTitleLabel: UILabel = {
        let l = UILabel()
        l.text = "Post"
        l.font = .systemFont(ofSize: 22, weight: .semibold)
        l.textColor = UIColor(hex: "#2C3331")
        return l
    }()
    private lazy var addPostButton: UIButton = {
        let b = UIButton(type: .system)
        b.setImage(UIImage(systemName: "plus"), for: .normal)
        b.tintColor = .white
        b.backgroundColor = UIColor(hex: "#2C3331")
        b.layer.cornerRadius = 16
        b.widthAnchor.constraint(equalToConstant: 32).isActive = true
        b.heightAnchor.constraint(equalToConstant: 32).isActive = true
        b.addTarget(self, action: #selector(addPostTapped), for: .touchUpInside)
        b.accessibilityLabel = "Add Post"
        return b
    }()
    private var postsCollectionView: UICollectionView!
    
    // MARK: - New Data (mock/demo)
    private var galleryItems: [GalleryItem] = [
        .init(title: "Morning Ride", mood: "🧘‍♂️ Calm", date: Date(), image: nil),         // Phuc's NEW changes
        .init(title: "Campus Sunset", mood: "🌅 Chill", date: Date(), image: nil),       // Phuc's NEW changes
        .init(title: "Studio Jam", mood: "🎧 Focus", date: Date(), image: nil),          // Phuc's NEW changes
        .init(title: "Coffee Time", mood: "☕️ Cozy", date: Date(), image: nil),          // Phuc's NEW changes
        .init(title: "Weekend Sketch", mood: "✏️ Creative", date: Date(), image: nil),   // Phuc's NEW changes
        .init(title: "Gallery Walk", mood: "🖼️ Artsy", date: Date(), image: nil),        // Phuc's NEW changes
        .init(title: "Quiet Night", mood: "🌙 Calm", date: Date(), image: nil)           // Phuc's NEW changes
    ]
    
    private var smallEmojiItems: [SmallItem] = (0..<12).map { _ in SmallItem(text: "🙂") }
    private var smallImageItems: [SmallItem] = (0..<12).map { _ in SmallItem(text: "🖼️") }
    private var smallSketchItems: [SmallItem] = (0..<12).map { _ in SmallItem(text: "✏️") }
    
    private var postItems: [PostItem] = [
        .init(id: "p1", title: "Kerr Hall Study Vibes", liked: false),
        .init(id: "p2", title: "Late Night Coding", liked: false),
        .init(id: "p3", title: "Silent Library Moment", liked: true),
        .init(id: "p4", title: "Greenbelt Walk", liked: false),
        .init(id: "p5", title: "Cycling Loop", liked: false),
        .init(id: "p6", title: "Sketching at Noon", liked: false)
    ]
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        definesPresentationContext = true
        setupUI()
        setupNotificationTableView()
        loadInitialNotifications()
        updateBadgeCount()
        setupContentSections()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // Ensure notification dropdown stays on top of scroll content
        notificationContainerView.layer.zPosition = 999
        view.bringSubviewToFront(notificationContainerView)
    }
    
    // MARK: - Setup
    private func setupUI() {
        // Use dynamic system colors so Light/Dark theme works
        view.backgroundColor = .customBackground

        // Welcome label
        welcomeLabel.text = "Welcome!"
        welcomeLabel.font = UIFont.systemFont(ofSize: 32, weight: .semibold)
        welcomeLabel.textColor = .label   // dynamic: dark text on light, light text on dark

        // Message label
        messageLabel.text = "Start your journey with SilentSocial!"
        messageLabel.font = UIFont.systemFont(ofSize: 18, weight: .regular)
        messageLabel.textColor = .secondaryLabel
        messageLabel.textAlignment = .center
        messageLabel.numberOfLines = 0

        // Notification container styling
        notificationContainerView.isHidden = true
        notificationContainerView.layer.cornerRadius = 12
        notificationContainerView.layer.masksToBounds = true
        notificationContainerView.backgroundColor = .secondarySystemBackground
        
        // Badge label styling
        badgeLabel.isHidden = true
        badgeLabel.backgroundColor = .systemBlue
        badgeLabel.textColor = .white
        badgeLabel.font = UIFont.systemFont(ofSize: 12, weight: .bold)
        badgeLabel.layer.cornerRadius = 10
        badgeLabel.clipsToBounds = true
        badgeLabel.textAlignment = .center
        
        // Button tints
        notificationButton.tintColor = UIColor(hex: "#275A7")
        settingsButton.tintColor = UIColor(hex: "#2C3331")
        settingsButton.isHidden = false
        settingsButton.isEnabled = true
        
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
        notificationTableView.backgroundColor = .customBackground
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
    
    // MARK: - NEW: Build the content below the message label
    private func setupContentSections() {
        // Scroll container under messageLabel
        contentScrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(contentScrollView)
        NSLayoutConstraint.activate([
            contentScrollView.topAnchor.constraint(equalTo: messageLabel.bottomAnchor, constant: 16),
            contentScrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            contentScrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            contentScrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
        
        // Stack for vertical sections
        contentStack.axis = .vertical
        contentStack.spacing = 16   // comfy vertical spacing
        contentStack.alignment = .fill
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        contentScrollView.addSubview(contentStack)
        NSLayoutConstraint.activate([
            contentStack.topAnchor.constraint(equalTo: contentScrollView.contentLayoutGuide.topAnchor, constant: 12),
            contentStack.leadingAnchor.constraint(equalTo: contentScrollView.frameLayoutGuide.leadingAnchor, constant: 16),
            contentStack.trailingAnchor.constraint(equalTo: contentScrollView.frameLayoutGuide.trailingAnchor, constant: -16),
            contentStack.bottomAnchor.constraint(equalTo: contentScrollView.contentLayoutGuide.bottomAnchor, constant: -28),
            contentStack.widthAnchor.constraint(equalTo: contentScrollView.frameLayoutGuide.widthAnchor, constant: -32)
        ])
        
        // ---- Gallery header (title + "+") ----
        let galleryHeader = UIStackView(arrangedSubviews: [galleryTitleLabel, UIView(), addToGalleryButton])
        galleryHeader.axis = .horizontal
        galleryHeader.alignment = .center
        galleryHeader.spacing = 12
        contentStack.addArrangedSubview(galleryHeader)
        
        // ---- Gallery (Masonry three-row pattern with dynamic sizes) ----
        galleryCollectionView = UICollectionView(frame: .zero, collectionViewLayout: Self.makeMasonryPatternGalleryLayout())
        galleryCollectionView.backgroundColor = .clear
        galleryCollectionView.showsHorizontalScrollIndicator = false
        galleryCollectionView.register(GalleryCell.self, forCellWithReuseIdentifier: GalleryCell.reuseID)
        galleryCollectionView.dataSource = self
        galleryCollectionView.delegate = self
        galleryCollectionView.contentInset = UIEdgeInsets(top: 0, left: 4, bottom: 0, right: 4)
        galleryCollectionView.heightAnchor.constraint(greaterThanOrEqualToConstant: 520).isActive = true // fits 3 rows comfortably
        contentStack.addArrangedSubview(galleryCollectionView)

        // Spacer below gallery
        let spacer = UIView()
        spacer.translatesAutoresizingMaskIntoConstraints = false
        spacer.heightAnchor.constraint(equalToConstant: 12).isActive = true
        contentStack.addArrangedSubview(spacer)
    }
    
    // MARK: - Actions
    @IBAction func notificationButtonTapped(_ sender: UIButton) {
        isNotificationMenuVisible.toggle()
        // Keep notification over everything
        notificationContainerView.layer.zPosition = 999
        view.bringSubviewToFront(notificationContainerView)
        UIView.animate(withDuration: 0.25) {
            self.notificationContainerView.isHidden = !self.isNotificationMenuVisible
        }
        notificationTableView.reloadData()
    }
    
    @IBAction func settingsButtonTapped(_ sender: UIButton) {
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
            UIView.animate(withDuration: 0.25) {
                self.notificationContainerView.isHidden = true
            }
        }
    }
    
    @objc private func addToGalleryTapped() {
        let ac = UIAlertController(title: "Add to Gallery", message: "What would you like to add?", preferredStyle: .actionSheet)
        ac.addAction(UIAlertAction(title: "Emoji", style: .default, handler: { _ in
            self.galleryItems.insert(.init(title: "New Emoji", mood: "😊 Happy", date: Date(), image: nil), at: 0)  // Phuc's NEW changes
            self.galleryCollectionView.reloadData()
        }))
        ac.addAction(UIAlertAction(title: "Images", style: .default, handler: { _ in
            self.galleryItems.insert(.init(title: "New Image", mood: "🖼️ Artsy", date: Date(), image: nil), at: 0)  // Phuc's NEW changes
            self.galleryCollectionView.reloadData()
        }))
        ac.addAction(UIAlertAction(title: "Sketches", style: .default, handler: { _ in
            self.galleryItems.insert(.init(title: "New Sketch", mood: "✏️ Creative", date: Date(), image: nil), at: 0) // Phuc's NEW changes
            self.galleryCollectionView.reloadData()
        }))
        ac.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        if let pop = ac.popoverPresentationController {
            pop.sourceView = addToGalleryButton
            pop.sourceRect = addToGalleryButton.bounds
        }
        present(ac, animated: true)
    }
    
    @objc private func addPostTapped() {
        let ac = UIAlertController(title: "Create a post!", message: nil, preferredStyle: .actionSheet)
        ac.addAction(UIAlertAction(title: "Image", style: .default, handler: { _ in
            self.showImageSourceSelection()     // Phuc's NEW changes
        }))
        ac.addAction(UIAlertAction(title: "Sketch", style: .default, handler: { _ in
            let a = UIAlertController(title: "Coming Soon", message: "Sketch post creation will be available soon.", preferredStyle: .alert)
            a.addAction(UIAlertAction(title: "OK", style: .default))
            self.present(a, animated: true)
        }))
        ac.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        if let pop = ac.popoverPresentationController {
            pop.sourceView = addToGalleryButton
            pop.sourceRect = addToGalleryButton.bounds
        }
        present(ac, animated: true)
    }
    
    // Phuc's NEW changes: Helper function to show menu selection about where the user wants to get the photo from
    private func showImageSourceSelection() {
        let sourceAlert = UIAlertController(
            title: "Select Photo Source",
            message: "Choose where to get your photo from",
            preferredStyle: .actionSheet
        )
        
        // Photo Library option - user choose to get an image from their phone's Photo Library
        sourceAlert.addAction(UIAlertAction(title: "Photo Library", style: .default, handler: { _ in
            self.openImagePicker(sourceType: .photoLibrary)
        }))
        
        // Camera option - user choose to use a camera to take an image
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            sourceAlert.addAction(UIAlertAction(title: "Camera", style: .default, handler: { _ in
                self.openImagePicker(sourceType: .camera)
            }))
        }
        
        // Cancel option
        sourceAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        if let pop = sourceAlert.popoverPresentationController {
            pop.sourceView = addToGalleryButton
            pop.sourceRect = addToGalleryButton.bounds
        }
        
        present(sourceAlert, animated: true)
    }
    
    // NEW: Helper function for user to select an image
    private func openImagePicker(sourceType: UIImagePickerController.SourceType) {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = self
        picker.allowsEditing = false
        present(picker, animated: true)
    }
    
    // NEW: Helper function to display preview of the currently selected image to add
    private func showImagePreview(image: UIImage) {
        let previewVC = ImagePreviewViewController(
            image: image,
            onUsePhoto: { [weak self] in
                self?.createImagePost(with: image)
            },
            onChooseDifferent: { [weak self] in
                self?.showImageSourceSelection()
            }
        )
        
        previewVC.modalPresentationStyle = .overCurrentContext
        previewVC.modalTransitionStyle = .crossDissolve
        present(previewVC, animated: true)
    }

    // NEW: Helper function to create a new post with the selected image
    private func createImagePost(with image: UIImage) {
        // Create a new gallery item with current date
        let newPost = GalleryItem(
            title: "New Image Post",
            mood: "📸 Captured",
            date: Date(),
            image: image
        )
        
        // Insert at index 0 (beginning) for reverse chronological order
        galleryItems.insert(newPost, at: 0)
        
        // Reload the gallery collection view to show the new post
        galleryCollectionView.reloadData()
        
        // Optional: Scroll to show the new post
        galleryCollectionView.scrollToItem(
            at: IndexPath(item: 0, section: 0),
            at: .top,
            animated: true
        )
        
        // Show success message when a new post with an image is successfully created and added to the Gallery
        let successAlert = UIAlertController(
            title: "Success!",
            message: "Your image post has been created and added to the gallery.",
            preferredStyle: .alert
        )
        successAlert.addAction(UIAlertAction(title: "OK", style: .default))
        present(successAlert, animated: true)
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

// MARK: - TableView (existing)
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

// MARK: - NEW: CollectionView DataSource/Delegate
extension DashboardViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    func numberOfSections(in collectionView: UICollectionView) -> Int { 1 }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if collectionView == galleryCollectionView { return galleryItems.count }
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: GalleryCell.reuseID, for: indexPath) as! GalleryCell
        cell.configure(with: galleryItems[indexPath.item])
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if collectionView == galleryCollectionView {
            let detail = PostDetailViewController(
                name: "Andy Finn",
                location: "University of Texas at Austin",
                emojiCaption: "😍 ❤️ 😘 🤣 ❤️ 😘 ❤️ 😘",
                date: galleryItems[indexPath.item].date
            )
            detail.modalPresentationStyle = .overCurrentContext
            detail.modalTransitionStyle = .crossDissolve
            present(detail, animated: true)
        }
    }
}

// MARK: - UIImagePickerController Delegate  (Phuc's NEW changes)
extension DashboardViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        // Dismiss the picker first
        picker.dismiss(animated: true)
        
        // Get the selected image
        if let image = info[.originalImage] as? UIImage {
            selectedImage = image
            // Show preview with options
            showImagePreview(image: image)
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        // User cancelled, so dismiss the picker
        picker.dismiss(animated: true)
    }
}

// MARK: - NEW: Compositional Layouts (responsive & comfy)
extension DashboardViewController {
    private static func makeSectionTitle(_ text: String) -> UILabel {
        let l = UILabel()
        l.text = text
        l.font = .systemFont(ofSize: 18, weight: .semibold)
        l.textColor = UIColor(hex: "#2C3331")
        return l
    }
    
    // Gallery: masonry layout pattern 1) 1x full-width, 2) 2x half, 3) 30/70 split
    static func makeMasonryPatternGalleryLayout() -> UICollectionViewCompositionalLayout {
        let layout = UICollectionViewCompositionalLayout { _, env in
            let width = env.container.effectiveContentSize.width
            let basePadding: CGFloat = 8
            let rowSpacing: CGFloat = 12

            // Dynamic heights based on container width for responsive feel
            let fullHeight = max(180, min(260, width * 0.35))
            let halfHeight = max(140, min(200, width * 0.26))
            let splitHeight = max(140, min(200, width * 0.26))

            // Row 1: one full-width item
            let r1ItemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                                    heightDimension: .absolute(fullHeight))
            let r1Item = NSCollectionLayoutItem(layoutSize: r1ItemSize)
            r1Item.contentInsets = .init(top: basePadding, leading: basePadding, bottom: basePadding, trailing: basePadding)
            let r1GroupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                                     heightDimension: .absolute(fullHeight + basePadding * 2))
            let r1Group = NSCollectionLayoutGroup.horizontal(layoutSize: r1GroupSize, subitems: [r1Item])

            // Row 2: two equal halves
            let r2ItemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(0.5),
                                                    heightDimension: .absolute(halfHeight))
            let r2Item = NSCollectionLayoutItem(layoutSize: r2ItemSize)
            r2Item.contentInsets = .init(top: basePadding, leading: basePadding, bottom: basePadding, trailing: basePadding)
            let r2GroupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                                     heightDimension: .absolute(halfHeight + basePadding * 2))
            let r2Group = NSCollectionLayoutGroup.horizontal(layoutSize: r2GroupSize, subitems: [r2Item, r2Item])

            // Row 3: 30% / 70% split
            let leftItemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(0.3),
                                                      heightDimension: .absolute(splitHeight))
            let rightItemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(0.7),
                                                       heightDimension: .absolute(splitHeight))
            let leftItem = NSCollectionLayoutItem(layoutSize: leftItemSize)
            let rightItem = NSCollectionLayoutItem(layoutSize: rightItemSize)
            leftItem.contentInsets = .init(top: basePadding, leading: basePadding, bottom: basePadding, trailing: basePadding)
            rightItem.contentInsets = .init(top: basePadding, leading: basePadding, bottom: basePadding, trailing: basePadding)
            let r3GroupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                                     heightDimension: .absolute(splitHeight + basePadding * 2))
            let r3Group = NSCollectionLayoutGroup.horizontal(layoutSize: r3GroupSize, subitems: [leftItem, rightItem])

            // Outer vertical group combines the three rows to form a repeating pattern of 5 items
            let outerHeight = fullHeight + halfHeight + splitHeight + basePadding * 6 + rowSpacing * 2
            let outerSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                                   heightDimension: .absolute(outerHeight))
            let outerGroup = NSCollectionLayoutGroup.vertical(layoutSize: outerSize, subitems: [r1Group, r2Group, r3Group])

            let section = NSCollectionLayoutSection(group: outerGroup)
            section.interGroupSpacing = rowSpacing
            section.contentInsets = .init(top: 0, leading: 0, bottom: 0, trailing: 0)
            section.orthogonalScrollingBehavior = .none
            return section
        }
        return layout
    }
    
    // Gallery: responsive width/height for comfy ~1.3–1.6 visible cards
    static func makeResponsiveGalleryLayout() -> UICollectionViewCompositionalLayout {
        let layout = UICollectionViewCompositionalLayout { _, env in
            let width = env.container.effectiveContentSize.width
            let targetVisibleCount: CGFloat = 1.45
            let cardWidth = min(max(240, width / targetVisibleCount - 16), 360)
            let cardHeight = max(160, min(220, cardWidth * 0.58)) // aspect-ish
            
            let itemSize = NSCollectionLayoutSize(widthDimension: .absolute(cardWidth),
                                                  heightDimension: .absolute(cardHeight))
            let item = NSCollectionLayoutItem(layoutSize: itemSize)
            item.contentInsets = .init(top: 0, leading: 8, bottom: 0, trailing: 8)
            
            let groupSize = NSCollectionLayoutSize(widthDimension: .absolute(width),
                                                   heightDimension: .absolute(cardHeight))
            let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
            let section = NSCollectionLayoutSection(group: group)
            section.orthogonalScrollingBehavior = .continuousGroupLeadingBoundary
            section.contentInsets = .init(top: 0, leading: 0, bottom: 6, trailing: 0)
            return section
        }
        return layout
    }
    
    // Horizontal strip: adaptive number per width (Emoji / Images / Sketches)
    static func makeAdaptiveStripLayout(itemWidth: CGFloat, height: CGFloat) -> UICollectionViewLayout {
        let layout = UICollectionViewCompositionalLayout { _, env in
            let columns = max(1, Int((env.container.effectiveContentSize.width - 16) / (itemWidth + 12)))
            let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0 / CGFloat(columns)),
                                                  heightDimension: .fractionalHeight(1.0))
            let item = NSCollectionLayoutItem(layoutSize: itemSize)
            item.contentInsets = .init(top: 4, leading: 6, bottom: 4, trailing: 6)
            
            let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                                   heightDimension: .absolute(height))
            let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
            let section = NSCollectionLayoutSection(group: group)
            section.orthogonalScrollingBehavior = .continuous
            section.interGroupSpacing = 0
            section.contentInsets = .init(top: 0, leading: 0, bottom: 0, trailing: 0)
            return section
        }
        return layout
    }
    
    //Post
    static func makeAdaptivePostsLayout() -> UICollectionViewCompositionalLayout {
        let layout = UICollectionViewCompositionalLayout { _, env in
            let width = env.container.effectiveContentSize.width
            let minCardWidth: CGFloat = 176
            let columns = max(2, Int((width + 12) / (minCardWidth + 16)))
            
            let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0 / CGFloat(columns)),
                                                  heightDimension: .estimated(230))
            let item = NSCollectionLayoutItem(layoutSize: itemSize)
            item.contentInsets = .init(top: 10, leading: 8, bottom: 10, trailing: 8) // comfy spacing
            
            let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                                   heightDimension: .estimated(480))
            let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, repeatingSubitem: item, count: columns)
            
            let section = NSCollectionLayoutSection(group: group)
            section.orthogonalScrollingBehavior = .none
            // More breathing room around the grid
            section.contentInsets = .init(top: 10, leading: 0, bottom: 24, trailing: 0)
            return section
        }
        return layout
    }
}

// MARK: - NEW: Preview Overlay
private extension DashboardViewController {
    func presentPreview(title: String, contentText: String) {
        let vc = ModalPreviewController(titleText: title, contentText: contentText)
        vc.modalPresentationStyle = .overFullScreen
        vc.modalTransitionStyle = .crossDissolve
        present(vc, animated: true)
    }
}

// MARK: - NEW: Cells & Models (local to this file)
struct GalleryItem {
    let title: String
    let mood: String
    let date: Date
    let image: UIImage?  // Phuc's NEW changes
}

struct SmallItem {
    let text: String
}

struct PostItem {
    let id: String
    let title: String
    var liked: Bool
}

// Gallery Cell (rounded, labels inside)
final class GalleryCell: UICollectionViewCell {
    static let reuseID = "GalleryCell"
    
    private let card = UIView()
    private let imageView = UIImageView() // Phuc's NEW changes: Image View
    private let titleLabel = UILabel()
    private let moodLabel = UILabel()
    private let dateLabel = UILabel()
    private let profileBadge = UIView()
    private let profileIcon = UIImageView()
    private let glassBackground = UIView()  // Phuc's NEW changes: Glass background behind date
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    required init?(coder: NSCoder) { super.init(coder: coder); setup() }
    
    private func setup() {
        contentView.backgroundColor = .clear
        
        card.translatesAutoresizingMaskIntoConstraints = false
        card.backgroundColor = UIColor(hex: "#F3F4F6")
        card.layer.cornerRadius = 16
        card.layer.masksToBounds = true
        contentView.addSubview(card)
        
        // Phuc's NEW Changes: Setup image view
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        card.addSubview(imageView)
        
        titleLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        moodLabel.font = .systemFont(ofSize: 14, weight: .regular)
        dateLabel.font = .systemFont(ofSize: 14, weight: .medium)
        titleLabel.textColor = UIColor(hex: "#2C3331")
        moodLabel.textColor = UIColor(hex: "#2C3331")
        dateLabel.textColor = UIColor(hex: "#2C3331")
        titleLabel.isHidden = true
        moodLabel.isHidden = true
        
        let vstack = UIStackView(arrangedSubviews: [dateLabel])
        vstack.axis = .vertical
        vstack.spacing = 4
        vstack.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(vstack)
        
        // Phuc's NEW Changes: Setup glass background for date
        glassBackground.translatesAutoresizingMaskIntoConstraints = false
        glassBackground.backgroundColor = UIColor.white.withAlphaComponent(0.3)
        glassBackground.layer.cornerRadius = 10
        glassBackground.layer.masksToBounds = true
        glassBackground.isHidden = true  // Only show for images

        // Add blur effect to glass background
        let blurEffect = UIBlurEffect(style: .light)
        let blurView = UIVisualEffectView(effect: blurEffect)
        blurView.translatesAutoresizingMaskIntoConstraints = false
        glassBackground.addSubview(blurView)

        NSLayoutConstraint.activate([
            blurView.topAnchor.constraint(equalTo: glassBackground.topAnchor),
            blurView.leadingAnchor.constraint(equalTo: glassBackground.leadingAnchor),
            blurView.trailingAnchor.constraint(equalTo: glassBackground.trailingAnchor),
            blurView.bottomAnchor.constraint(equalTo: glassBackground.bottomAnchor)
        ])

        card.insertSubview(glassBackground, belowSubview: vstack)
        
        // Profile badge overlay (top-right)
        profileBadge.translatesAutoresizingMaskIntoConstraints = false
        profileBadge.backgroundColor = .white
        profileBadge.layer.cornerRadius = 22
        profileBadge.layer.borderWidth = 2
        profileBadge.layer.borderColor = UIColor(hex: "#2C3331").cgColor
        card.addSubview(profileBadge)
        
        profileIcon.translatesAutoresizingMaskIntoConstraints = false
        profileIcon.image = UIImage(systemName: "person")
        profileIcon.tintColor = UIColor(hex: "#2C3331")
        profileBadge.addSubview(profileIcon)
        
        NSLayoutConstraint.activate([
            card.topAnchor.constraint(equalTo: contentView.topAnchor),
            card.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            card.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            card.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            
            // Phuc's NEW Changes: Image View constraints
            imageView.topAnchor.constraint(equalTo: card.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: card.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: card.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: card.bottomAnchor),
            
            vstack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 12),
            vstack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -12),
            vstack.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -12),
            vstack.topAnchor.constraint(greaterThanOrEqualTo: card.topAnchor, constant: 12),
            
            // Phuc's NEW Changes
            glassBackground.leadingAnchor.constraint(equalTo: vstack.leadingAnchor, constant: -8),
            glassBackground.topAnchor.constraint(equalTo: vstack.topAnchor, constant: -8),
            glassBackground.bottomAnchor.constraint(equalTo: vstack.bottomAnchor, constant: 8),
            glassBackground.widthAnchor.constraint(equalToConstant: 108),

            profileBadge.widthAnchor.constraint(equalToConstant: 44),
            profileBadge.heightAnchor.constraint(equalToConstant: 44),
            profileBadge.topAnchor.constraint(equalTo: card.topAnchor, constant: 12),
            profileBadge.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -12),
            profileIcon.centerXAnchor.constraint(equalTo: profileBadge.centerXAnchor),
            profileIcon.centerYAnchor.constraint(equalTo: profileBadge.centerYAnchor)
        ])
    }
    
    func configure(with item: GalleryItem) {
        let df = DateFormatter()
        df.locale = Locale.current
        df.dateFormat = "MMM. d, yyyy"
        dateLabel.text = df.string(from: item.date)
        
        // Phuc's NEW Changes: Display the image if there is any
        if let image = item.image {
            imageView.image = image
            glassBackground.isHidden = false
        } else {
            // If no image, use placeholder background
            imageView.backgroundColor = UIColor(hex: "#E5E7EB")
            glassBackground.isHidden = true
        }
    }
}

// Small item box (Emoji / Images / Sketches)
final class SmallItemCell: UICollectionViewCell {
    static let reuseID = "SmallItemCell"
    
    private let box = UIView()
    private let label = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    required init?(coder: NSCoder) { super.init(coder: coder); setup() }
    
    private func setup() {
        contentView.backgroundColor = .clear
        box.translatesAutoresizingMaskIntoConstraints = false
        box.backgroundColor = UIColor(hex: "#EEF2F7")
        box.layer.cornerRadius = 12
        box.layer.borderColor = UIColor(hex: "#E5E7EB").cgColor
        box.layer.borderWidth = 1
        contentView.addSubview(box)
        
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 20, weight: .semibold)
        label.textAlignment = .center
        label.textColor = UIColor(hex: "#2C3331")
        box.addSubview(label)
        
        NSLayoutConstraint.activate([
            box.topAnchor.constraint(equalTo: contentView.topAnchor),
            box.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            box.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            box.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            
            label.centerXAnchor.constraint(equalTo: box.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: box.centerYAnchor)
        ])
    }
    
    func configure(with item: SmallItem) {
        label.text = item.text
    }
}

// Post grid cell
final class PostCell: UICollectionViewCell {
    static let reuseID = "PostCell"
    
    private let card = UIView()
    private let titleLabel = UILabel()
    private let likeButton = UIButton(type: .system)
    var onToggleLike: (() -> Void)?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    required init?(coder: NSCoder) { super.init(coder: coder); setup() }
    
    private func setup() {
        contentView.backgroundColor = .clear
        
        card.translatesAutoresizingMaskIntoConstraints = false
        card.backgroundColor = UIColor(hex: "#FFFFFF")
        card.layer.cornerRadius = 14
        card.layer.borderWidth = 1
        card.layer.borderColor = UIColor(hex: "#E5E7EB").cgColor
        card.layer.shadowColor = UIColor.black.cgColor
        card.layer.shadowOpacity = 0.05
        card.layer.shadowOffset = CGSize(width: 0, height: 2)
        card.layer.shadowRadius = 4
        contentView.addSubview(card)
        
        titleLabel.font = .systemFont(ofSize: 14, weight: .semibold)
        titleLabel.textColor = UIColor(hex: "#2C3331")
        titleLabel.numberOfLines = 3
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        likeButton.setTitle("", for: .normal)
        likeButton.tintColor = .systemRed // red when selected (SF Symbol)
        likeButton.translatesAutoresizingMaskIntoConstraints = false
        likeButton.addTarget(self, action: #selector(tapLike), for: .touchUpInside)
        
        let heartConfig = UIImage.SymbolConfiguration(pointSize: 18, weight: .regular, scale: .medium)
        likeButton.setImage(UIImage(systemName: "heart", withConfiguration: heartConfig), for: .normal)
        likeButton.setImage(UIImage(systemName: "heart.fill", withConfiguration: heartConfig), for: .selected)
        
        card.addSubview(titleLabel)
        card.addSubview(likeButton)
        
        NSLayoutConstraint.activate([
            card.topAnchor.constraint(equalTo: contentView.topAnchor),
            card.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            card.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            card.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            
            likeButton.topAnchor.constraint(equalTo: card.topAnchor, constant: 10),
            likeButton.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 10),
            
            titleLabel.topAnchor.constraint(equalTo: likeButton.bottomAnchor, constant: 10),
            titleLabel.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 14),
            titleLabel.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -14),
            titleLabel.bottomAnchor.constraint(lessThanOrEqualTo: card.bottomAnchor, constant: -14),
            card.heightAnchor.constraint(greaterThanOrEqualToConstant: 190)
        ])
    }
    
    func configure(with item: PostItem) {
        titleLabel.text = item.title
        likeButton.isSelected = item.liked // fills & turns red when true
    }
    
    @objc private func tapLike() {
        likeButton.isSelected.toggle()
        onToggleLike?()
    }
}

// MARK: - NEW: Simple full-screen preview controller
final class ModalPreviewController: UIViewController {
    private let titleText: String
    private let contentText: String
    
    init(titleText: String, contentText: String) {
        self.titleText = titleText
        self.contentText = contentText
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        container.backgroundColor = .white
        container.layer.cornerRadius = 16
        
        let titleLabel = UILabel()
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = titleText
        titleLabel.font = .systemFont(ofSize: 18, weight: .semibold)
        titleLabel.textColor = UIColor(hex: "#2C3331")
        titleLabel.textAlignment = .center
        
        let bigLabel = UILabel()
        bigLabel.translatesAutoresizingMaskIntoConstraints = false
        bigLabel.text = contentText
        bigLabel.font = .systemFont(ofSize: 48, weight: .bold)
        bigLabel.textAlignment = .center
        
        let closeBtn = UIButton(type: .system)
        closeBtn.translatesAutoresizingMaskIntoConstraints = false
        closeBtn.setTitle("Close", for: .normal)
        closeBtn.addTarget(self, action: #selector(dismissSelf), for: .touchUpInside)
        
        view.addSubview(container)
        container.addSubview(titleLabel)
        container.addSubview(bigLabel)
        container.addSubview(closeBtn)
        
        NSLayoutConstraint.activate([
            container.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            container.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            container.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 24),
            container.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -24),
            
            titleLabel.topAnchor.constraint(equalTo: container.topAnchor, constant: 18),
            titleLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),
            
            bigLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 12),
            bigLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            bigLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),
            
            closeBtn.topAnchor.constraint(equalTo: bigLabel.bottomAnchor, constant: 16),
            closeBtn.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -16),
            closeBtn.centerXAnchor.constraint(equalTo: container.centerXAnchor)
        ])
        
        // tap outside to close
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissSelf))
        view.addGestureRecognizer(tap)
    }
    
    @objc private func dismissSelf() { dismiss(animated: true) }
}

// MARK: - Post Detail (modal)
final class PostDetailViewController: UIViewController {
    private let name: String
    private let location: String
    private let emojiCaption: String
    private let date: Date
    
    init(name: String, location: String, emojiCaption: String, date: Date) {
        self.name = name
        self.location = location
        self.emojiCaption = emojiCaption
        self.date = date
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
        let blur = UIVisualEffectView(effect: UIBlurEffect(style: .systemMaterial))
        blur.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(blur)
        
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        container.backgroundColor = .white
        container.layer.cornerRadius = 16
        container.layer.borderWidth = 1
        container.layer.borderColor = UIColor(hex: "#E5E7EB").cgColor
        view.addSubview(container)
        
        let headerImage = UIView()
        headerImage.translatesAutoresizingMaskIntoConstraints = false
        headerImage.backgroundColor = UIColor(hex: "#D1D5DB")
        headerImage.layer.cornerRadius = 12
        headerImage.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        
        let avatarBadge = UIView()
        avatarBadge.translatesAutoresizingMaskIntoConstraints = false
        avatarBadge.backgroundColor = .white
        avatarBadge.layer.cornerRadius = 18
        avatarBadge.layer.borderWidth = 2
        avatarBadge.layer.borderColor = UIColor(hex: "#2C3331").cgColor
        
        let avatarIcon = UIImageView(image: UIImage(systemName: "person"))
        avatarIcon.translatesAutoresizingMaskIntoConstraints = false
        avatarIcon.tintColor = UIColor(hex: "#2C3331")
        
        avatarBadge.addSubview(avatarIcon)
        
        let nameLabel = UILabel()
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.text = name
        nameLabel.font = .systemFont(ofSize: 20, weight: .bold)
        nameLabel.textColor = UIColor(hex: "#2C3331")
        
        let locationLabel = UILabel()
        locationLabel.translatesAutoresizingMaskIntoConstraints = false
        locationLabel.textColor = UIColor(hex: "#2C3331")
        locationLabel.font = .systemFont(ofSize: 14, weight: .regular)
        locationLabel.text = "\u{1F4CC} " + location
        
        let nameStack = UIStackView(arrangedSubviews: [nameLabel, locationLabel])
        nameStack.translatesAutoresizingMaskIntoConstraints = false
        nameStack.axis = .vertical
        nameStack.spacing = 2
        
        let headerStack = UIStackView(arrangedSubviews: [avatarBadge, nameStack])
        headerStack.translatesAutoresizingMaskIntoConstraints = false
        headerStack.axis = .horizontal
        headerStack.spacing = 12
        headerStack.alignment = .center
        
        let emojiLabel = UILabel()
        emojiLabel.translatesAutoresizingMaskIntoConstraints = false
        emojiLabel.text = emojiCaption
        emojiLabel.font = .systemFont(ofSize: 20, weight: .regular)

        let closeBtn = UIButton(type: .system)
        closeBtn.translatesAutoresizingMaskIntoConstraints = false
        closeBtn.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
        closeBtn.tintColor = UIColor(hex: "#2C3331")
        closeBtn.addTarget(self, action: #selector(dismissSelf), for: .touchUpInside)
        
        let dateLabel = UILabel()
        dateLabel.translatesAutoresizingMaskIntoConstraints = false
        let df = DateFormatter()
        df.locale = Locale.current
        df.dateFormat = "MMM. d, yyyy"
        dateLabel.text = df.string(from: date)
        dateLabel.font = .systemFont(ofSize: 14, weight: .medium)
        dateLabel.textColor = UIColor(hex: "#2C3331")
        
        let dotsContainer = UIStackView()
        dotsContainer.translatesAutoresizingMaskIntoConstraints = false
        dotsContainer.axis = .horizontal
        dotsContainer.spacing = 6
        dotsContainer.alignment = .center
        let dot1 = UIView()
        dot1.translatesAutoresizingMaskIntoConstraints = false
        dot1.backgroundColor = UIColor(hex: "#D1D5DB")
        dot1.layer.cornerRadius = 4
        let dot2 = UIView()
        dot2.translatesAutoresizingMaskIntoConstraints = false
        dot2.backgroundColor = UIColor(hex: "#9CA3AF")
        dot2.layer.cornerRadius = 4
        dotsContainer.addArrangedSubview(dot1)
        dotsContainer.addArrangedSubview(dot2)
        
        let contentStack = UIStackView(arrangedSubviews: [headerImage, headerStack, emojiLabel])
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        contentStack.axis = .vertical
        contentStack.spacing = 12
        
        container.addSubview(contentStack)
        container.addSubview(dateLabel)
        container.addSubview(dotsContainer)
        container.addSubview(closeBtn)
        
        NSLayoutConstraint.activate([
            blur.topAnchor.constraint(equalTo: view.topAnchor),
            blur.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            blur.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            blur.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            container.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            container.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 24),
            container.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            container.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            
            headerImage.heightAnchor.constraint(equalToConstant: 180),
            
            avatarBadge.widthAnchor.constraint(equalToConstant: 36),
            avatarBadge.heightAnchor.constraint(equalToConstant: 36),
            avatarIcon.centerXAnchor.constraint(equalTo: avatarBadge.centerXAnchor),
            avatarIcon.centerYAnchor.constraint(equalTo: avatarBadge.centerYAnchor),
            
            contentStack.topAnchor.constraint(equalTo: container.topAnchor, constant: 12),
            contentStack.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 12),
            contentStack.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -12),

            dateLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -12),
            dateLabel.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -18),

            dotsContainer.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            dotsContainer.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -18),
            dot1.widthAnchor.constraint(equalToConstant: 8),
            dot1.heightAnchor.constraint(equalToConstant: 8),
            dot2.widthAnchor.constraint(equalToConstant: 8),
            dot2.heightAnchor.constraint(equalToConstant: 8),
            closeBtn.topAnchor.constraint(equalTo: container.topAnchor, constant: 10),
            closeBtn.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -10),
            closeBtn.widthAnchor.constraint(equalToConstant: 28),
            closeBtn.heightAnchor.constraint(equalToConstant: 28)
        ])

        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissSelf))
        view.addGestureRecognizer(tap)
    }
    
    @objc private func dismissSelf() { dismiss(animated: true) }
}

// MARK: - Image Preview Modal (Phuc's NEW Changes)
final class ImagePreviewViewController: UIViewController {
    private let image: UIImage
    private let onUsePhoto: () -> Void
    private let onChooseDifferent: () -> Void
    
    init(image: UIImage, onUsePhoto: @escaping () -> Void, onChooseDifferent: @escaping () -> Void) {
        self.image = image
        self.onUsePhoto = onUsePhoto
        self.onChooseDifferent = onChooseDifferent
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    private func setupUI() {
        // Semi-transparent background
        view.backgroundColor = UIColor.black.withAlphaComponent(0.4)
        
        // Main container card
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        container.backgroundColor = .white
        container.layer.cornerRadius = 16
        container.layer.masksToBounds = true
        view.addSubview(container)
        
        // Message label at top
        let messageLabel = UILabel()
        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        messageLabel.text = "Would you like to use this photo or choose a different one?"
        messageLabel.font = .systemFont(ofSize: 16, weight: .regular)
        messageLabel.textColor = UIColor(hex: "#2C3331")
        messageLabel.textAlignment = .center
        messageLabel.numberOfLines = 2
        
        // Image view (MAIN FOCUS)
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.image = image
        imageView.contentMode = .scaleAspectFill  // CHANGED: Fill to match width
        imageView.clipsToBounds = true
        
        // Buttons
        let useButton = UIButton(type: .system)
        useButton.translatesAutoresizingMaskIntoConstraints = false
        useButton.setTitle("Use This Photo", for: .normal)
        useButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        useButton.setTitleColor(.systemBlue, for: .normal)
        useButton.backgroundColor = UIColor(hex: "#F3F4F6")
        useButton.layer.cornerRadius = 8
        useButton.addTarget(self, action: #selector(usePhotoTapped), for: .touchUpInside)
        useButton.heightAnchor.constraint(equalToConstant: 48).isActive = true
        
        let chooseDifferentButton = UIButton(type: .system)
        chooseDifferentButton.translatesAutoresizingMaskIntoConstraints = false
        chooseDifferentButton.setTitle("Choose Different Photo", for: .normal)
        chooseDifferentButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        chooseDifferentButton.setTitleColor(.systemBlue, for: .normal)
        chooseDifferentButton.backgroundColor = UIColor(hex: "#F3F4F6")
        chooseDifferentButton.layer.cornerRadius = 8
        chooseDifferentButton.addTarget(self, action: #selector(chooseDifferentTapped), for: .touchUpInside)
        chooseDifferentButton.heightAnchor.constraint(equalToConstant: 48).isActive = true
        
        let cancelButton = UIButton(type: .system)
        cancelButton.translatesAutoresizingMaskIntoConstraints = false
        cancelButton.setTitle("Cancel", for: .normal)
        cancelButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .regular)
        cancelButton.setTitleColor(.systemGray, for: .normal)
        cancelButton.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)
        cancelButton.heightAnchor.constraint(equalToConstant: 44).isActive = true
        
        // Button stack
        let buttonStack = UIStackView(arrangedSubviews: [
            useButton,
            chooseDifferentButton,
            cancelButton
        ])
        buttonStack.translatesAutoresizingMaskIntoConstraints = false
        buttonStack.axis = .vertical
        buttonStack.spacing = 12
        buttonStack.distribution = .fill
        
        // Add all to container
        container.addSubview(messageLabel)
        container.addSubview(imageView)
        container.addSubview(buttonStack)
        
        // Constraints
        NSLayoutConstraint.activate([
            // Container centered, with margins
            container.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            container.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            container.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 16),
            container.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -16),
            
            // Message at top with padding
            messageLabel.topAnchor.constraint(equalTo: container.topAnchor, constant: 16),
            messageLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            messageLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),
            
            // Image below message - UPDATED: Matches button width
            imageView.topAnchor.constraint(equalTo: messageLabel.bottomAnchor, constant: 16),
            imageView.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            imageView.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),
            imageView.heightAnchor.constraint(equalToConstant: 200),  // INCREASED: More height for better visibility
            
            // Buttons at bottom with padding
            buttonStack.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 16),
            buttonStack.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            buttonStack.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),
            buttonStack.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -16)
        ])
        
        // Tap outside to dismiss
        let tap = UITapGestureRecognizer(target: self, action: #selector(cancelTapped))
        view.addGestureRecognizer(tap)
    }

    
    @objc private func usePhotoTapped() {
        dismiss(animated: true, completion: onUsePhoto)
    }
    
    @objc private func chooseDifferentTapped() {
        dismiss(animated: true, completion: onChooseDifferent)
    }
    
    @objc private func cancelTapped() {
        dismiss(animated: true)
    }
}


// MARK: - Color Extension (existing)
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

// MARK: - UIIMage Extension (Phuc's NEW Changes)
extension UIImage {
    // NEW: Helper function to resize the
    func resizedToWidth(width: CGFloat) -> UIImage? {
        // Avoid division by zero
        guard self.size.width > 0 else { return self }
        
        let ratio = width / self.size.width
        let height = self.size.height * ratio
        
        let newSize = CGSize(width: width, height: height)
        let renderer = UIGraphicsImageRenderer(size: newSize)
        
        return renderer.image { _ in
            self.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
    
    // NEW: Helper function to resize the height of an UIImage
    func resizedToHeight(_ maxHeight: CGFloat) -> UIImage? {
        guard self.size.height > 0 else { return self }
        
        let ratio = maxHeight / self.size.height
        let width = self.size.width * ratio
        
        let newSize = CGSize(width: width, height: maxHeight)
        let renderer = UIGraphicsImageRenderer(size: newSize)
        
        return renderer.image { _ in
            self.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}
