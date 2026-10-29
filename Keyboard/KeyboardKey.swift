import UIKit

/// A light key surface; one keyboard-level blur avoids a blur view per key.
final class KeyboardKey: UIButton {
    var restingColor: UIColor = .secondarySystemBackground
    var pressedColor: UIColor = .tertiarySystemFill
    override var isHighlighted: Bool {
        didSet {
            backgroundColor = isHighlighted ? pressedColor : restingColor
            layer.shadowOpacity = isHighlighted ? 0 : 0.12
        }
    }
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        layer.borderColor = UIColor.separator.withAlphaComponent(0.12).resolvedColor(with: traitCollection).cgColor
    }
}
