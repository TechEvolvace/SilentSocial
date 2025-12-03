//  Project: SilentSocial
//  Names: Phuc Dinh, Nicholas Ng, Preston Tu, Rui Xue
//  Course: CS329E
//  PostsProfileViewController.swift

import UIKit
import FirebaseAuth
import FirebaseFirestore

final class PostsProfileViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate {
    private let db = Firestore.firestore()
    private var uid: String? {
        return Auth.auth().currentUser?.uid
    }

    private var displayName: String = ""
    private var emojiCaption: String = ""

    private var segmentIndex: Int = 0
    private var items: [PostThumb] = []
    private static let cache = NSCache<NSString, UIImage>()
    private var listener: ListenerRegistration?

    private let headerStack = UIStackView()
    private let avatarView = UIView()
    private let avatarIcon = UIImageView()
    private let nameLabel = UILabel()
    private let emojiLabel = UILabel()
    private let segmentedControl = UISegmentedControl(items: ["Image", "Sketch"])
    private var collectionView: UICollectionView!
    private let emptyLabel = UILabel()

    struct PostThumb {
        let id: String
        let imageURL: URL
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Profile"
        view.backgroundColor = .systemBackground
        setupUI()
        loadProfile()
        loadPosts()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadProfile()
        startListening()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopListening()
    }

    private func setupUI() {
        headerStack.axis = .horizontal
        headerStack.spacing = 12
        headerStack.alignment = .center

        avatarView.translatesAutoresizingMaskIntoConstraints = false
        avatarView.backgroundColor = UIColor.systemGray5
        avatarView.layer.cornerRadius = 28
        avatarView.widthAnchor.constraint(equalToConstant: 56).isActive = true
        avatarView.heightAnchor.constraint(equalToConstant: 56).isActive = true

        avatarIcon.translatesAutoresizingMaskIntoConstraints = false
        avatarIcon.image = UIImage(systemName: "person")
        avatarIcon.tintColor = UIColor.label
        avatarView.addSubview(avatarIcon)
        NSLayoutConstraint.activate([
            avatarIcon.centerXAnchor.constraint(equalTo: avatarView.centerXAnchor),
            avatarIcon.centerYAnchor.constraint(equalTo: avatarView.centerYAnchor)
        ])

        nameLabel.font = .systemFont(ofSize: 22, weight: .bold)
        nameLabel.textColor = .label

        emojiLabel.font = .systemFont(ofSize: 18, weight: .regular)
        emojiLabel.textColor = .label

        let nameStack = UIStackView(arrangedSubviews: [nameLabel, emojiLabel])
        nameStack.axis = .vertical
        nameStack.spacing = 4

        headerStack.translatesAutoresizingMaskIntoConstraints = false
        headerStack.addArrangedSubview(avatarView)
        headerStack.addArrangedSubview(nameStack)
        view.addSubview(headerStack)

        segmentedControl.selectedSegmentIndex = 0
        segmentedControl.translatesAutoresizingMaskIntoConstraints = false
        segmentedControl.addTarget(self, action: #selector(segmentChanged(_:)), for: .valueChanged)
        view.addSubview(segmentedControl)

        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = 12
        layout.minimumInteritemSpacing = 12
        let side = (view.bounds.width - 12 * 3) / 2
        layout.itemSize = CGSize(width: side, height: side)
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.backgroundColor = .clear
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(ThumbCell.self, forCellWithReuseIdentifier: "ThumbCell")
        view.addSubview(collectionView)

        emptyLabel.text = "No posts yet"
        emptyLabel.textAlignment = .center
        emptyLabel.textColor = .secondaryLabel
        emptyLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(emptyLabel)

        NSLayoutConstraint.activate([
            headerStack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            headerStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            headerStack.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -16),

            segmentedControl.topAnchor.constraint(equalTo: headerStack.bottomAnchor, constant: 12),
            segmentedControl.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            segmentedControl.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

            collectionView.topAnchor.constraint(equalTo: segmentedControl.bottomAnchor, constant: 12),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -12),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            emptyLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }

    @objc private func segmentChanged(_ sender: UISegmentedControl) {
        segmentIndex = sender.selectedSegmentIndex
        loadPosts()
        startListening()
    }

    private func loadProfile() {
        guard let uid = uid else { return }
        FirebaseService.shared.userDocRef(uid: uid).getDocument { [weak self] snap, err in
            guard let self = self else { return }
            if let data = snap?.data() {
                self.displayName = (data["displayName"] as? String) ?? ""
                self.emojiCaption = (data["currentEmoji"] as? String) ?? ""
                self.nameLabel.text = self.displayName
                self.emojiLabel.text = self.emojiCaption
            }
        }
    }

    private func loadPosts() {
        guard let uid = uid else { return }
        let type = segmentIndex == 0 ? "image" : "sketch"
        FirebaseService.shared.userPostsCollection(uid: uid)
            .whereField("type", isEqualTo: type)
            .order(by: "createdAt", descending: true)
            .getDocuments { [weak self] snap, err in
                guard let self = self else { return }
                var next: [PostThumb] = []
                if let docs = snap?.documents {
                    for d in docs {
                        if let s = d.data()["imageURL"] as? String, let url = URL(string: s) {
                            next.append(PostThumb(id: d.documentID, imageURL: url))
                        }
                    }
                }
                self.items = next
                self.emptyLabel.isHidden = !next.isEmpty
                self.collectionView.reloadData()
            }
    }

    private func startListening() {
        stopListening()
        guard let uid = uid else { return }
        let type = segmentIndex == 0 ? "image" : "sketch"
        let q = FirebaseService.shared.userPostsCollection(uid: uid)
            .whereField("type", isEqualTo: type)
            .order(by: "createdAt", descending: true)
        listener = q.addSnapshotListener { [weak self] snap, _ in
            guard let self = self else { return }
            var next: [PostThumb] = []
            if let docs = snap?.documents {
                for d in docs {
                    if let s = d.data()["imageURL"] as? String, let url = URL(string: s) {
                        next.append(PostThumb(id: d.documentID, imageURL: url))
                    }
                }
            }
            self.items = next
            self.emptyLabel.isHidden = !next.isEmpty
            self.collectionView.reloadData()
        }
    }

    private func stopListening() {
        listener?.remove()
        listener = nil
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return items.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ThumbCell", for: indexPath) as! ThumbCell
        let item = items[indexPath.item]
        if let cached = PostsProfileViewController.cache.object(forKey: item.imageURL.absoluteString as NSString) {
            cell.imageView.image = cached
        } else {
            URLSession.shared.dataTask(with: item.imageURL) { data, _, _ in
                if let data = data, let img = UIImage(data: data) {
                    PostsProfileViewController.cache.setObject(img, forKey: item.imageURL.absoluteString as NSString)
                    DispatchQueue.main.async { cell.imageView.image = img }
                }
            }.resume()
        }
        return cell
    }
}

final class ThumbCell: UICollectionViewCell {
    let imageView = UIImageView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.backgroundColor = UIColor.systemGray5
        contentView.layer.cornerRadius = 12
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        contentView.addSubview(imageView)
        NSLayoutConstraint.activate([
            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            imageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
}
