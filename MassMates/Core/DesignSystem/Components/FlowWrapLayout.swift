import SwiftUI

struct FlowWrapLayout: Layout, Sendable {
    var horizontalSpacing: CGFloat = 8
    var verticalSpacing: CGFloat = 8

    init(horizontalSpacing: CGFloat = 8, verticalSpacing: CGFloat = 8) {
        self.horizontalSpacing = horizontalSpacing
        self.verticalSpacing = verticalSpacing
    }

    func makeCache(subviews: Subviews) -> [CGSize] {
        subviews.map { $0.sizeThatFits(.unspecified) }
    }

    func updateCache(_ cache: inout [CGSize], subviews: Subviews) {
        cache = subviews.map { $0.sizeThatFits(.unspecified) }
    }

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout [CGSize]) -> CGSize {
        let maxAvailableWidth = proposal.replacingUnspecifiedDimensions().width
        var totalHeight: CGFloat = 0
        var currentLineWidth: CGFloat = 0
        var currentLineHeight: CGFloat = 0

        for size in cache {
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

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout [CGSize]) {
        var currentX = bounds.minX
        var currentY = bounds.minY
        var currentLineHeight: CGFloat = 0

        for (subview, size) in zip(subviews, cache) {
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
}
