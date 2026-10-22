import SwiftUI

struct FlowWrapLayout: Layout, Sendable {
    // MARK: - Dependencies & State
    var horizontalSpacing: CGFloat = 8
    var verticalSpacing: CGFloat = 8

    // MARK: - Init
    init(horizontalSpacing: CGFloat = 8, verticalSpacing: CGFloat = 8) {
        self.horizontalSpacing = horizontalSpacing
        self.verticalSpacing = verticalSpacing
    }

    // MARK: - Body / Public API
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxAvailableWidth = proposal.replacingUnspecifiedDimensions().width
        var totalHeight: CGFloat = 0
        var currentLineWidth: CGFloat = 0
        var currentLineHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if currentLineWidth + size.width > maxAvailableWidth, currentLineWidth > 0 {
                totalHeight += currentLineHeight + verticalSpacing
                currentLineWidth = 0
                currentLineHeight = 0
            }
            currentLineWidth += size.width + horizontalSpacing
            currentLineHeight = max(currentLineHeight, size.height)
        }
        totalHeight += currentLineHeight
        return CGSize(width: maxAvailableWidth, height: totalHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var currentX = bounds.minX
        var currentY = bounds.minY
        var currentLineHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if currentX + size.width > bounds.maxX, currentX > bounds.minX {
                currentX = bounds.minX
                currentY += currentLineHeight + verticalSpacing
                currentLineHeight = 0
            }
            subview.place(at: CGPoint(x: currentX, y: currentY), proposal: ProposedViewSize(size))
            currentX += size.width + horizontalSpacing
            currentLineHeight = max(currentLineHeight, size.height)
        }
    }

    // MARK: - Subviews / Private Helpers
}
