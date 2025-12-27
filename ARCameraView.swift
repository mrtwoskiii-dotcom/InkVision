import SwiftUI
import RealityKit
import ARKit

struct ARCameraView: UIViewRepresentable {
    var image: UIImage?
    var scale: Float
    var rotation: Double
    @Binding var captureSnapshot: Bool

    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)
        
        // Configure AR for Body Tracking
        let config = ARBodyTrackingConfiguration()
        config.automaticSkeletonScaleEstimationEnabled = true
        
        // Check if the device supports body tracking (A12 chip or newer)
        if ARBodyTrackingConfiguration.isSupported {
            arView.session.run(config)
        } else {
            print("Body tracking is not supported on this device.")
        }
        
        arView.session.delegate = context.coordinator
        context.coordinator.arView = arView
        
        return arView
    }

    func updateUIView(_ uiView: ARView, context: Context) {
        if let image = image {
            context.coordinator.updateTattoo(image: image)
        }
        context.coordinator.updateTransform(scale: scale, rotation: rotation)
        
        if captureSnapshot {
            uiView.snapshot(saveToHDR: false) { image in
                if let image = image {
                    UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
                }
                DispatchQueue.main.async {
                    self.captureSnapshot = false
                }
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    class Coordinator: NSObject, ARSessionDelegate {
        var arView: ARView?
        var tattooEntity: ModelEntity?
        var anchorEntity: AnchorEntity?

        func updateTattoo(image: UIImage) {
            guard tattooEntity == nil else { return } // Only create once

            // Create a 3D plane for the tattoo (15cm x 15cm)
            let mesh = MeshResource.generatePlane(width: 0.15, depth: 0.15)
            var material = UnlitMaterial()

            // Apply the tattoo image as a texture
            if let cgImage = image.cgImage,
               let texture = try? TextureResource.generate(from: cgImage, options: .init(semantic: .color)) {
                material.color = .init(texture: .init(texture))
                material.baseColor = MaterialColorParameter.texture(texture)
                material.tintColor = UIColor.white.withAlphaComponent(0.99)
            }

            let entity = ModelEntity(mesh: mesh, materials: [material])
            self.tattooEntity = entity
        }
        
        func updateTransform(scale: Float, rotation: Double) {
            guard let entity = tattooEntity else { return }
            // Scale the plane (X and Z dimensions)
            entity.scale = SIMD3<Float>(scale, 1, scale)
            // Rotate around the Y axis (the normal of the plane)
            entity.orientation = simd_quatf(angle: Float(rotation), axis: SIMD3<Float>(0, 1, 0))
        }

        func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
            guard let bodyAnchor = anchors.first(where: { $0 is ARBodyAnchor }) as? ARBodyAnchor,
                  let entity = tattooEntity,
                  let arView = arView else { return }

            // Find the Left Forearm joint
            // You can change this to .rightForearm or .leftHand
            if let jointTransform = bodyAnchor.skeleton.modelTransform(for: .leftForearm) {
                let globalTransform = simd_mul(bodyAnchor.transform, jointTransform)
                
                // Create an anchor at the forearm position if it doesn't exist
                if anchorEntity == nil {
                    let newAnchor = AnchorEntity(world: globalTransform)
                    newAnchor.addChild(entity)
                    arView.scene.addAnchor(newAnchor)
                    anchorEntity = newAnchor
                } else {
                    // Update position to follow the arm
                    anchorEntity?.transform.matrix = globalTransform
                }
            }
        }
    }
}