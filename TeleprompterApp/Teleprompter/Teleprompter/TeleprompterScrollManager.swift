import UIKit

/// Drives the automatic upward scrolling with a display link.
/// Speed is a plain number (points per second) set by the user; there is no automatic speech tracking.
final class TeleprompterScrollManager: ObservableObject {
    @Published private(set) var isPlaying = false

    weak var scrollView: UIScrollView?
    var speed: CGFloat = 40

    private var displayLink: CADisplayLink?
    private var lastTimestamp: CFTimeInterval = 0
    private var exactY: CGFloat = 0

    deinit {
        displayLink?.invalidate()
    }

    func toggle() {
        isPlaying ? pause() : play()
    }

    func play() {
        guard !isPlaying, let sv = scrollView else { return }
        if sv.contentOffset.y >= maxOffset(of: sv) - 1, maxOffset(of: sv) > 0 {
            sv.setContentOffset(.zero, animated: false)
        }
        exactY = sv.contentOffset.y
        lastTimestamp = 0
        isPlaying = true
        let link = CADisplayLink(target: self, selector: #selector(tick(_:)))
        link.add(to: .main, forMode: .common)
        displayLink = link
    }

    /// Pausing keeps the current reading position.
    func pause() {
        isPlaying = false
        displayLink?.invalidate()
        displayLink = nil
    }

    /// Jumps back to the top and pauses.
    func restart() {
        pause()
        exactY = 0
        scrollView?.setContentOffset(.zero, animated: false)
    }

    private func maxOffset(of sv: UIScrollView) -> CGFloat {
        max(sv.contentSize.height - sv.bounds.height, 0)
    }

    @objc private func tick(_ link: CADisplayLink) {
        guard let sv = scrollView else {
            pause()
            return
        }
        if lastTimestamp == 0 {
            lastTimestamp = link.timestamp
            return
        }
        let dt = min(link.timestamp - lastTimestamp, 0.1)
        lastTimestamp = link.timestamp

        // Manual scrolling by finger: let the user move freely, auto-scroll continues afterwards.
        if sv.isDragging || sv.isDecelerating {
            exactY = sv.contentOffset.y
            return
        }
        if abs(sv.contentOffset.y - exactY) > 1 {
            exactY = sv.contentOffset.y
        }

        let maxY = maxOffset(of: sv)
        exactY = min(exactY + speed * CGFloat(dt), maxY)
        sv.contentOffset = CGPoint(x: 0, y: exactY)
        if exactY >= maxY {
            pause()
        }
    }
}
