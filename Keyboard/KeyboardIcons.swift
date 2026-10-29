import UIKit

enum KeyboardIcons {
    static func image(for title: String) -> UIImage? {
        guard ["⌫", "⇧", "↵"].contains(title) else { return nil }
        return UIGraphicsImageRenderer(size: CGSize(width: 36, height: 28)).image { _ in
            UIColor.black.setStroke()
            UIColor.black.setFill()
            let path = UIBezierPath()
            path.lineWidth = 2.4
            path.lineCapStyle = .round
            path.lineJoinStyle = .round
            if title == "⌫" {
                path.move(to: CGPoint(x: 12, y: 4))
                path.addLine(to: CGPoint(x: 31, y: 4))
                path.addQuadCurve(to: CGPoint(x: 33, y: 6), controlPoint: CGPoint(x: 33, y: 4))
                path.addLine(to: CGPoint(x: 33, y: 22))
                path.addQuadCurve(to: CGPoint(x: 31, y: 24), controlPoint: CGPoint(x: 33, y: 24))
                path.addLine(to: CGPoint(x: 12, y: 24))
                path.addLine(to: CGPoint(x: 2, y: 14))
                path.close()
                path.move(to: CGPoint(x: 16, y: 10)); path.addLine(to: CGPoint(x: 24, y: 18))
                path.move(to: CGPoint(x: 24, y: 10)); path.addLine(to: CGPoint(x: 16, y: 18))
                path.stroke()
            } else if title == "⇧" {
                path.move(to: CGPoint(x: 18, y: 2))
                for point in [CGPoint(x: 32, y: 16), CGPoint(x: 25, y: 16), CGPoint(x: 25, y: 26), CGPoint(x: 11, y: 26), CGPoint(x: 11, y: 16), CGPoint(x: 4, y: 16)] { path.addLine(to: point) }
                path.close(); path.fill()
            } else {
                path.move(to: CGPoint(x: 29, y: 3))
                path.addLine(to: CGPoint(x: 29, y: 14))
                path.addQuadCurve(to: CGPoint(x: 25, y: 18), controlPoint: CGPoint(x: 29, y: 18))
                path.addLine(to: CGPoint(x: 7, y: 18))
                path.move(to: CGPoint(x: 14, y: 11)); path.addLine(to: CGPoint(x: 7, y: 18)); path.addLine(to: CGPoint(x: 14, y: 25))
                path.stroke()
            }
        }.withRenderingMode(.alwaysTemplate)
    }
}
