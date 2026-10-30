import Foundation

struct TeleprompterSettings: Codable, Equatable {
    enum TextAlignment: String, Codable, CaseIterable {
        case left
        case center
    }

    // Panel size as a fraction of the available screen area.
    var panelWidth: Double = 0.9
    var panelHeight: Double = 0.4
    // Panel position: 0...1 of the free space (0.5, 0.0 = top centre).
    var panelX: Double = 0.5
    var panelY: Double = 0.0

    var fontSize: Double = 34
    /// Scroll speed in points per second.
    var speed: Double = 40
    var textOpacity: Double = 1.0
    var backgroundOpacity: Double = 0.5
    var textAlignment: TextAlignment = .center
    var lineSpacing: Double = 10

    static let widthRange: ClosedRange<Double> = 0.3...1.0
    static let heightRange: ClosedRange<Double> = 0.15...0.8
    static let fontSizeRange: ClosedRange<Double> = 16...100
    static let speedRange: ClosedRange<Double> = 5...200
    static let opacityRange: ClosedRange<Double> = 0...1
    static let lineSpacingRange: ClosedRange<Double> = 0...40

    mutating func clampValues() {
        panelWidth = Self.clamp(panelWidth, Self.widthRange)
        panelHeight = Self.clamp(panelHeight, Self.heightRange)
        panelX = Self.clamp(panelX, 0...1)
        panelY = Self.clamp(panelY, 0...1)
        fontSize = Self.clamp(fontSize, Self.fontSizeRange)
        speed = Self.clamp(speed, Self.speedRange)
        textOpacity = Self.clamp(textOpacity, Self.opacityRange)
        backgroundOpacity = Self.clamp(backgroundOpacity, Self.opacityRange)
        lineSpacing = Self.clamp(lineSpacing, Self.lineSpacingRange)
    }

    private static func clamp(_ value: Double, _ range: ClosedRange<Double>) -> Double {
        min(max(value, range.lowerBound), range.upperBound)
    }
}
