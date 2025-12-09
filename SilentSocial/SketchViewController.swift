import UIKit

final class SketchCanvasView: UIView {
    var strokeColor: UIColor = .black
    var lineWidth: CGFloat = 5
    private var currentPath: UIBezierPath?
    private var paths: [UIBezierPath] = []

    override init(frame: CGRect) {
        super.init(frame: frame)
        isMultipleTouchEnabled = false
        backgroundColor = .white
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        isMultipleTouchEnabled = false
        backgroundColor = .white
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let p = touches.first?.location(in: self) else { return }
        let path = UIBezierPath()
        path.lineWidth = lineWidth
        path.move(to: p)
        currentPath = path
        paths.append(path)
        setNeedsDisplay()
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let p = touches.first?.location(in: self), let path = currentPath else { return }
        path.addLine(to: p)
        setNeedsDisplay()
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        currentPath = nil
        setNeedsDisplay()
    }

    override func draw(_ rect: CGRect) {
        strokeColor.setStroke()
        for path in paths { path.stroke() }
    }

    func clear() {
        paths.removeAll()
        setNeedsDisplay()
    }
}

final class SketchViewController: UIViewController {
    var onSave: ((UIImage) -> Void)?
    private let canvas = SketchCanvasView()
    private let topBar = UIStackView()
    private let cancelButton = UIButton(type: .system)
    private let saveButton = UIButton(type: .system)
    private let clearButton = UIButton(type: .system)
    private let colorBar = UIStackView()
    private let colors: [UIColor] = [
        .black,
        .red,
        .systemBlue,
        .systemGreen,
        .systemOrange,
        .systemPurple
    ]

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground

        topBar.axis = .horizontal
        topBar.alignment = .center
        topBar.distribution = .equalSpacing
        topBar.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(topBar)

        cancelButton.setTitle("Cancel", for: .normal)
        saveButton.setTitle("Save", for: .normal)
        clearButton.setTitle("Clear", for: .normal)
        topBar.addArrangedSubview(cancelButton)
        topBar.addArrangedSubview(clearButton)
        topBar.addArrangedSubview(saveButton)

        cancelButton.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)
        saveButton.addTarget(self, action: #selector(saveTapped), for: .touchUpInside)
        clearButton.addTarget(self, action: #selector(clearTapped), for: .touchUpInside)

        canvas.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(canvas)

        colorBar.axis = .horizontal
        colorBar.alignment = .center
        colorBar.distribution = .fillEqually
        colorBar.spacing = 8
        colorBar.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(colorBar)

        for c in colors {
            let b = UIButton(type: .system)
            b.backgroundColor = c
            b.layer.cornerRadius = 14
            b.heightAnchor.constraint(equalToConstant: 28).isActive = true
            b.addTarget(self, action: #selector(colorTapped(_:)), for: .touchUpInside)
            colorBar.addArrangedSubview(b)
        }

        let guide = view.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            topBar.topAnchor.constraint(equalTo: guide.topAnchor, constant: 12),
            topBar.leadingAnchor.constraint(equalTo: guide.leadingAnchor, constant: 16),
            topBar.trailingAnchor.constraint(equalTo: guide.trailingAnchor, constant: -16),

            colorBar.topAnchor.constraint(equalTo: topBar.bottomAnchor, constant: 12),
            colorBar.leadingAnchor.constraint(equalTo: guide.leadingAnchor, constant: 16),
            colorBar.trailingAnchor.constraint(equalTo: guide.trailingAnchor, constant: -16),

            canvas.topAnchor.constraint(equalTo: colorBar.bottomAnchor, constant: 12),
            canvas.leadingAnchor.constraint(equalTo: guide.leadingAnchor, constant: 12),
            canvas.trailingAnchor.constraint(equalTo: guide.trailingAnchor, constant: -12),
            canvas.bottomAnchor.constraint(equalTo: guide.bottomAnchor, constant: -12)
        ])
    }

    @objc private func cancelTapped() { dismiss(animated: true) }
    @objc private func clearTapped() { canvas.clear() }

    @objc private func saveTapped() {
        let bounds = canvas.bounds
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = UIScreen.main.scale
        let renderer = UIGraphicsImageRenderer(size: bounds.size, format: format)
        let image = renderer.image { ctx in
            UIColor.white.setFill()
            ctx.fill(CGRect(origin: .zero, size: bounds.size))
            canvas.layer.render(in: ctx.cgContext)
        }
        onSave?(image)
        dismiss(animated: true)
    }

    @objc private func colorTapped(_ sender: UIButton) {
        guard let idx = colorBar.arrangedSubviews.firstIndex(of: sender) else { return }
        canvas.strokeColor = colors[idx]
    }
}
