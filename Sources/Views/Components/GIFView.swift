import SwiftUI
import UIKit
import ImageIO

struct GIFView: UIViewRepresentable {
    let name: String

    func makeUIView(context: Context) -> GIFContainerView {
        let view = GIFContainerView()
        view.loadGIF(named: name)
        return view
    }

    func updateUIView(_ uiView: GIFContainerView, context: Context) {}
}

final class GIFContainerView: UIView {
    private let imageView = UIImageView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        clipsToBounds = true
        backgroundColor = .clear

        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        imageView.backgroundColor = .clear
        addSubview(imageView)
    }

    required init?(coder: NSCoder) { fatalError() }

    override func layoutSubviews() {
        super.layoutSubviews()
        imageView.frame = bounds
    }

    override var intrinsicContentSize: CGSize {
        CGSize(width: UIView.noIntrinsicMetric, height: UIView.noIntrinsicMetric)
    }

    func loadGIF(named name: String) {
        guard let url = Bundle.main.url(forResource: name, withExtension: "gif"),
              let data = try? Data(contentsOf: url),
              let source = CGImageSourceCreateWithData(data as CFData, nil)
        else { return }

        let count = CGImageSourceGetCount(source)
        var images: [UIImage] = []
        var duration: Double = 0

        for i in 0..<count {
            if let cgImage = CGImageSourceCreateImageAtIndex(source, i, nil) {
                images.append(UIImage(cgImage: cgImage))
                if let props = CGImageSourceCopyPropertiesAtIndex(source, i, nil) as? [String: Any],
                   let gifProps = props[kCGImagePropertyGIFDictionary as String] as? [String: Any] {
                    let delay = gifProps[kCGImagePropertyGIFUnclampedDelayTime as String] as? Double
                        ?? gifProps[kCGImagePropertyGIFDelayTime as String] as? Double
                        ?? 0.1
                    duration += delay
                }
            }
        }

        imageView.animationImages = images
        imageView.animationDuration = duration
        imageView.animationRepeatCount = 0
        imageView.startAnimating()
    }
}
