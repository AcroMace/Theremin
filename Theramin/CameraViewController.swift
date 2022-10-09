//
//  CameraViewController.swift
//  Theramin
//
//  Created by Andy Cho on 10/3/22.
//

import UIKit
import AVFoundation
import Vision

class CameraViewController: UIViewController {

    private let MinFingertipObservationConfidence: Float = 0.3

    private var cameraView: CameraView?
    let toneGenerator = ToneGenerator()
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

extension CameraViewController: HandPositionControllerDelegate {
    func processPoints(points: [CGPoint]) {
        // Check that we have both points.
        guard points.count > 0 else {
            cameraView?.showPoints([], color: .clear)
            toneGenerator.stop()
            return
        }

        // Convert points from AVFoundation coordinates to UIKit coordinates.
        let previewLayer = cameraView?.previewLayer
        let uiPoints = points.compactMap { previewLayer?.layerPointConverted(fromCaptureDevicePoint: $0) }
        cameraView?.showPoints(uiPoints, color: .red)

        // This is a value between 0 and 1
        let frequencyMultiplier = 1.0 - points[0].x
        toneGenerator.playFrequency(frequencyMultiplier: frequencyMultiplier)
    }
}
