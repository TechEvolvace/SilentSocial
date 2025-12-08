import UIKit

final class EmojiPickerViewController: UIViewController {
    var onPick: ((String) -> Void)?

    private let backdrop = UIVisualEffectView(effect: UIBlurEffect(style: .systemMaterial))
    private let container = UIView()
    private let titleLabel = UILabel()
    private let cancelButton = UIButton(type: .system)
    private let useButton = UIButton(type: .system)
    private var selectedEmoji: String?
    private lazy var emojis: [String] = EmojiDataLoader.allEmojis()
    private let pageVC = UIPageViewController(transitionStyle: .scroll, navigationOrientation: .horizontal, options: nil)
    private let pageControl = UIPageControl()
    private var gridPages: [EmojiGridViewController] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
        isModalInPresentation = true

        backdrop.translatesAutoresizingMaskIntoConstraints = false
        backdrop.isUserInteractionEnabled = true
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissSelf))
        backdrop.addGestureRecognizer(tap)
        view.addSubview(backdrop)

        container.translatesAutoresizingMaskIntoConstraints = false
        container.backgroundColor = .white
        container.layer.cornerRadius = 16
        container.layer.borderWidth = 1
        container.layer.borderColor = UIColor(hex: "#E5E7EB").cgColor
        view.addSubview(container)

        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = "Pick Emoji"
        titleLabel.font = .systemFont(ofSize: 18, weight: .semibold)
        titleLabel.textColor = UIColor(hex: "#2C3331")
        titleLabel.textAlignment = .center

        // Build pages of emojis (64 per page)
        var pages: [[String]] = []
        let perPage = 96
        var idx = 0
        while idx < emojis.count {
            let end = min(idx + perPage, emojis.count)
            pages.append(Array(emojis[idx..<end]))
            idx = end
        }
        gridPages = pages.map { list in
            let vc = EmojiGridViewController(emojis: list) { [weak self] e in
                self?.selectedEmoji = e
                self?.useButton.isEnabled = true
            }
            return vc
        }

        addChild(pageVC)
        pageVC.view.translatesAutoresizingMaskIntoConstraints = false
        pageVC.setViewControllers(gridPages.isEmpty ? [] : [gridPages[0]], direction: .forward, animated: false)
        pageVC.didMove(toParent: self)
        pageVC.dataSource = self
        pageVC.delegate = self
        container.addSubview(pageVC.view)

        cancelButton.translatesAutoresizingMaskIntoConstraints = false
        cancelButton.setTitle("Cancel", for: .normal)
        cancelButton.addTarget(self, action: #selector(dismissSelf), for: .touchUpInside)

        useButton.translatesAutoresizingMaskIntoConstraints = false
        useButton.setTitle("Use Emoji", for: .normal)
        useButton.addTarget(self, action: #selector(useEmoji), for: .touchUpInside)

        container.addSubview(titleLabel)
        container.addSubview(pageVC.view)
        container.addSubview(cancelButton)
        container.addSubview(useButton)

        NSLayoutConstraint.activate([
            backdrop.topAnchor.constraint(equalTo: view.topAnchor),
            backdrop.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backdrop.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            backdrop.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            container.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16),
            container.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16),
            container.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 24),
            container.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -24),

            titleLabel.topAnchor.constraint(equalTo: container.topAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),

            pageVC.view.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 12),
            pageVC.view.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            pageVC.view.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),

            
        ])

        let buttonRow = UIStackView(arrangedSubviews: [cancelButton, useButton])
        buttonRow.axis = .horizontal
        buttonRow.distribution = .fillEqually
        buttonRow.spacing = 12
        buttonRow.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(buttonRow)
        NSLayoutConstraint.activate([
            buttonRow.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            buttonRow.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),
            buttonRow.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -16),
            pageVC.view.bottomAnchor.constraint(equalTo: buttonRow.topAnchor, constant: -12)
        ])

        pageControl.translatesAutoresizingMaskIntoConstraints = false
        pageControl.numberOfPages = gridPages.count
        pageControl.currentPage = 0
        pageControl.isUserInteractionEnabled = false
        container.addSubview(pageControl)
        NSLayoutConstraint.activate([
            pageControl.bottomAnchor.constraint(equalTo: buttonRow.topAnchor, constant: -8),
            pageControl.centerXAnchor.constraint(equalTo: container.centerXAnchor)
        ])
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }

    @objc private func dismissSelf() { dismiss(animated: true) }

    @objc private func useEmoji() {
        guard let e = selectedEmoji else { return }
        onPick?(e)
        dismiss(animated: true)
    }

}

extension EmojiPickerViewController: UIPageViewControllerDataSource, UIPageViewControllerDelegate {
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let idx = gridPages.firstIndex(where: { $0 === viewController }) else { return nil }
        if idx == 0 { return nil }
        return gridPages[idx - 1]
    }
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let idx = gridPages.firstIndex(where: { $0 === viewController }) else { return nil }
        if idx >= gridPages.count - 1 { return nil }
        return gridPages[idx + 1]
    }
    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        if completed, let current = pageViewController.viewControllers?.first, let idx = gridPages.firstIndex(where: { $0 === current }) {
            pageControl.currentPage = idx
        }
    }
}


final class EmojiGridViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    private let emojis: [String]
    private let onSelect: (String) -> Void
    private var collectionView: UICollectionView!
    init(emojis: [String], onSelect: @escaping (String) -> Void) {
        self.emojis = emojis
        self.onSelect = onSelect
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    override func viewDidLoad() {
        super.viewDidLoad()
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumInteritemSpacing = 8
        layout.minimumLineSpacing = 8
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.backgroundColor = .clear
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(EmojiGridCell.self, forCellWithReuseIdentifier: EmojiGridCell.reuseID)
        view.addSubview(collectionView)
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int { emojis.count }
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: EmojiGridCell.reuseID, for: indexPath) as! EmojiGridCell
        cell.configure(text: emojis[indexPath.item])
        return cell
    }
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        onSelect(emojis[indexPath.item])
    }
    // dynamic sizing
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = collectionView.bounds.width
        let spacing: CGFloat = 8
        var columns = Int(floor((width + spacing) / 48))
        columns = max(7, min(columns, 10))
        let totalSpacing = spacing * CGFloat(columns - 1)
        let side = floor((width - totalSpacing) / CGFloat(columns))
        return CGSize(width: side, height: side)
    }
}

final class EmojiGridCell: UICollectionViewCell {
    static let reuseID = "EmojiGridCell"
    private let label = UILabel()
    private let bg = UIView()
    override init(frame: CGRect) {
        super.init(frame: frame)
        bg.translatesAutoresizingMaskIntoConstraints = false
        bg.backgroundColor = UIColor(hex: "#F3F4F6")
        bg.layer.cornerRadius = 8
        bg.layer.borderColor = UIColor.systemBlue.cgColor
        contentView.addSubview(bg)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 24)
        contentView.addSubview(label)
        NSLayoutConstraint.activate([
            bg.topAnchor.constraint(equalTo: contentView.topAnchor),
            bg.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            bg.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            bg.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            label.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])
    }
    required init?(coder: NSCoder) { super.init(coder: coder) }
    func configure(text: String) { label.text = text }
    override var isHighlighted: Bool {
        didSet { updateHighlight() }
    }
    override var isSelected: Bool {
        didSet { updateHighlight() }
    }
    private func updateHighlight() {
        let active = isHighlighted || isSelected
        bg.layer.borderWidth = active ? 2 : 0
        let scale: CGFloat = active ? 0.95 : 1.0
        contentView.transform = CGAffineTransform(scaleX: scale, y: scale)
    }
}
