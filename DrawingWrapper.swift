import SwiftUI
import PencilKit

struct DrawingWrapper: UIViewRepresentable {
    @Binding var canvasView: PKCanvasView

    func makeUIView(context: Context) -> PKCanvasView {
        canvasView.drawingPolicy = .anyInput
        canvasView.backgroundColor = .white
        // Set a default tool so drawing works immediately
        canvasView.tool = PKInkingTool(.pen, color: .black, width: 15)
        return canvasView
    }

    func updateUIView(_ uiView: PKCanvasView, context: Context) {
        // Do nothing
    }
}