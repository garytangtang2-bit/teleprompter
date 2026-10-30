import SwiftUI
import UIKit

/// The scrolling script text. Uses UIScrollView so position, pausing and finger scrolling are exact.
struct TeleprompterTextView: UIViewRepresentable {
    let text: String
    let settings: TeleprompterSettings
    let manager: TeleprompterScrollManager

    func makeUIView(context: Context) -> PrompterScrollView {
        let view = PrompterScrollView()
        manager.scrollView = view
        return view
    }

    func updateUIView(_ uiView: PrompterScrollView, context: Context) {
        manager.scrollView = uiView
        manager.speed = CGFloat(settings.speed)
        uiView.apply(
            text: text,
            fontSize: settings.fontSize,
            lineSpacing: settings.lineSpacing,
            alignment: settings.textAlignment,
            textOpacity: settings.textOpacity
        )
    }
}

final class PrompterScrollView: UIScrollView {
    private struct Style: Equatable {
        var text: String
        var fontSize: Double
        var lineSpacing: Double
        var alignment: TeleprompterSettings.TextAlignment
        var textOpacity: Double
    }

    private let label = UILabel()
    private var appliedStyle: Style?
    private let horizontalPadding: CGFloat = 20
    private let topPadding: CGFloat = 12

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        showsVerticalScrollIndicator = false
        alwaysBounceVertical = false
        label.numberOfLines = 0
        addSubview(label)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    func apply(text: String, fontSize: Double, lineSpacing: Double,
               alignment: TeleprompterSettings.TextAlignment, textOpacity: Double) {
        let style = Style(text: text, fontSize: fontSize, lineSpacing: lineSpacing,
                          alignment: alignment, textOpacity: textOpacity)
        guard style != appliedStyle else { return }
        appliedStyle = style

        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = (alignment == .center) ? .center : .left
        paragraph.lineSpacing = CGFloat(lineSpacing)

        let shadow = NSShadow()
        shadow.shadowColor = UIColor.black.withAlphaComponent(0.8 * CGFloat(textOpacity))
        shadow.shadowBlurRadius = 3
        shadow.shadowOffset = CGSize(width: 0, height: 1)

        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: CGFloat(fontSize), weight: .semibold),
            .foregroundColor: UIColor.white.withAlphaComponent(CGFloat(textOpacity)),
            .paragraphStyle: paragraph,
            .shadow: shadow
        ]
        label.attributedText = NSAttributedString(string: text.isEmpty ? " " : text, attributes: attributes)
        setNeedsLayout()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let width = max(bounds.width - horizontalPadding * 2, 1)
        let fitted = label.sizeThatFits(CGSize(width: width, height: .greatestFiniteMagnitude))
        label.frame = CGRect(x: horizontalPadding, y: topPadding, width: width, height: fitted.height)

        // Extra space at the bottom so the last line can scroll up to the top of the panel.
        let contentHeight = topPadding + fitted.height + bounds.height
        let newSize = CGSize(width: bounds.width, height: contentHeight)
        if contentSize != newSize {
            contentSize = newSize
        }
    }
}
