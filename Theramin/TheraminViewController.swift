//
//  TheraminViewController.swift
//  Theramin
//
//  Created by Andy Cho on 10/3/22.
//

import UIKit
import AVFoundation

class TheraminViewController: UIViewController {

    private var cameraView: CameraView?
    let leftHandToneGenerator = ToneGenerator(minFrequency: Tone.a4, maxFrequency: Tone.a5)
    let rightHandToneGenerator = ToneGenerator(minFrequency: Tone.a5, maxFrequency: Tone.a6)
    let handPositionController = HandPositionController()

    override func viewDidLoad() {
        super.viewDidLoad()

        cameraView = CameraView(frame: view.bounds)
        if let cameraView {
            view.addSubview(cameraView)
        }

        handPositionController.delegate = self
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if handPositionController.cameraFeedSession == nil {
            cameraView?.previewLayer.videoGravity = .resizeAspectFill
            handPositionController.setup()
            cameraView?.previewLayer.session = handPositionController.cameraFeedSession
        }
        handPositionController.start()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        handPositionController.stop()
    }
}

extension TheraminViewController: HandPositionControllerDelegate {
    func processPoints(points: [CGPoint]) {
        // Check that we have at least one hand
        guard points.count > 0 else {
            cameraView?.showPoints([], color: .clear)
            leftHandToneGenerator.stop()
            rightHandToneGenerator.stop()
            return
        }

        // Convert points from AVFoundation coordinates to UIKit coordinates.
        let previewLayer = cameraView?.previewLayer
        let uiPoints = points.compactMap { previewLayer?.layerPointConverted(fromCaptureDevicePoint: $0) }
        cameraView?.showPoints(uiPoints, color: .red)

        // We use the original captureDevicePoint since it's a value between 0 and 1
        // Note that it's rotated so we use the x value
        let firstPointFrequencyMultiplier = 1.0 - points[0].x

        if points.count == 1 {
            // If there's only one hand, we have to stop the other one
            if isLeftHand(layerPoint: uiPoints[0], previewLayer: previewLayer) {
                leftHandToneGenerator.playFrequency(frequencyMultiplier: firstPointFrequencyMultiplier)
                rightHandToneGenerator.stop()
            } else {
                rightHandToneGenerator.playFrequency(frequencyMultiplier: firstPointFrequencyMultiplier)
                leftHandToneGenerator.stop()
            }
        } else {
            // We have at least two hands
            let secondPointFrequencyMultiplier = 1.0 - points[1].x
            if isLeftHand(layerPoint: uiPoints[0], previewLayer: previewLayer) {
                leftHandToneGenerator.playFrequency(frequencyMultiplier: firstPointFrequencyMultiplier)
                rightHandToneGenerator.playFrequency(frequencyMultiplier: secondPointFrequencyMultiplier)
            } else {
                rightHandToneGenerator.playFrequency(frequencyMultiplier: firstPointFrequencyMultiplier)
                leftHandToneGenerator.playFrequency(frequencyMultiplier: secondPointFrequencyMultiplier)
            }
        }
    }

    private func isLeftHand(layerPoint: CGPoint, previewLayer: AVCaptureVideoPreviewLayer?) -> Bool {
        let width = previewLayer?.frame.width ?? 0
        return layerPoint.x < width / 2.0
    }
}
