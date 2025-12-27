import SwiftUI
import PencilKit
import RealityKit

struct ContentView: View {
    @State private var canvasView = PKCanvasView()
    @State private var isPreviewing = false
    @State private var generatedImage: UIImage? = nil
    @State private var tattooScale: Float = 1.0
    @State private var tattooRotation: Double = 0.0
    @State private var captureSnapshot = false

    var body: some View {
        ZStack {
            if isPreviewing {
                // Layer 1 (Bottom): ARCameraView
                ARCameraView(image: generatedImage, scale: tattooScale, rotation: tattooRotation, captureSnapshot: $captureSnapshot)
                    .ignoresSafeArea()
                
                // Layer 3 (Top): Back to Editor
                VStack {
                    Spacer()
                    Button(action: {
                        isPreviewing = false
                    }) {
                        Text("Back to Editor")
                            .font(.headline)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    
                    // Controls
                    VStack(spacing: 20) {
                        HStack {
                            Text("Size").foregroundColor(.white).bold()
                            Slider(value: $tattooScale, in: 0.5...3.0)
                        }
                        HStack {
                            Text("Rotate").foregroundColor(.white).bold()
                            Slider(value: $tattooRotation, in: 0...(2 * .pi))
                        }
                        
                        Button(action: {
                            captureSnapshot = true
                        }) {
                            Text("Save Photo")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding(10)
                                .background(Color.white.opacity(0.3))
                                .cornerRadius(8)
                        }
                    }
                    .padding()
                    .background(Color.black.opacity(0.5))
                    .cornerRadius(15)
                    .padding(.horizontal)
                    .padding(.bottom, 50)
                }
            } else {
                // Drawing Mode
                DrawingWrapper(canvasView: $canvasView)
                
                VStack {
                    Spacer()
                    Button(action: {
                        // Temporarily make background clear to capture only the ink
                        canvasView.backgroundColor = .clear
                        let rect = canvasView.bounds
                        generatedImage = canvasView.drawing.image(from: rect, scale: 1.0)
                        canvasView.backgroundColor = .white
                        isPreviewing = true
                    }) {
                        Text("Try On")
                            .font(.headline)
                            .padding()
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .padding(.bottom, 50)
                }
            }
        }
    }
}