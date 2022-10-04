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

    private let MinConfidence: Float = 0.3

    private var cameraView: CameraView?

    private let videoDataOutputQueue = DispatchQueue(label: "CameraFeedDataOutput", qos: .userInteractive)
    private var cameraFeedSession: AVCaptureSession?
    private var handPoseRequest = VNDetectHumanHandPoseRequest()

    override func viewDidLoad() {
        super.viewDidLoad()

        cameraView = CameraView(frame: view.bounds)
        if let cameraView {
            view.addSubview(cameraView)
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if cameraFeedSession == nil {
            cameraView?.previewLayer.videoGravity = .resizeAspectFill
            setupAVSession()
            cameraView?.previewLayer.session = cameraFeedSession
        }
        cameraFeedSession?.startRunning()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        cameraFeedSession?.stopRunning()
    }

    private func setupAVSession() {
        guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) else {
            fatalError("Could not find a front facing camera")
        }

        guard let deviceInput = try? AVCaptureDeviceInput(device: videoDevice) else {
            fatalError("Could not create video input")
        }

        let session = AVCaptureSession()
        session.beginConfiguration()
        session.sessionPreset = .high

        guard session.canAddInput(deviceInput) else {
            fatalError("Could not add video device input to the session")
        }
        session.addInput(deviceInput)

        let dataOutput = AVCaptureVideoDataOutput()
        if session.canAddOutput(dataOutput) {
            session.addOutput(dataOutput)
            dataOutput.alwaysDiscardsLateVideoFrames = true
            dataOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_420YpCbCr8BiPlanarFullRange)]
            dataOutput.setSampleBufferDelegate(self, queue: videoDataOutputQueue)
        } else {
            fatalError("Could not add video data output to the session")
        }
        session.commitConfiguration()
        cameraFeedSession = session
    }

    func processPoints(points: [CGPoint]) {
        // Check that we have both points.
        guard points.count > 0 else {
            cameraView?.showPoints([], color: .clear)
            return
        }

        // Convert points from AVFoundation coordinates to UIKit coordinates.
        let previewLayer = cameraView?.previewLayer
        cameraView?.showPoints(points.compactMap { previewLayer?.layerPointConverted(fromCaptureDevicePoint: $0) }, color: .red)
    }
}

extension CameraViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    public func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        var points: [CGPoint] = []

        defer {
            DispatchQueue.main.sync {
                self.processPoints(points: points)
            }
        }

        let handler = VNImageRequestHandler(cmSampleBuffer: sampleBuffer, orientation: .up, options: [:])
        do {
            // Perform VNDetectHumanHandPoseRequest
            try handler.perform([handPoseRequest])

            points = handPoseRequest.results?.compactMap { pointForHandObservation($0) } ?? []
        } catch {
            cameraFeedSession?.stopRunning()
            print("Vision error")
        }
    }

    /**
     * Will return the point for the index finger if possible, thumb if not
     */
    private func pointForHandObservation(_ observation: VNHumanHandPoseObservation) -> CGPoint? {
        do {
            let indexFingerPoints = try observation.recognizedPoints(.indexFinger)
            if let indexTipPoint = indexFingerPoints[.indexTip], indexTipPoint.confidence > MinConfidence {
                return visionCoordinatesToVideoCoordinates(indexTipPoint)
            }

            let thumbPoints = try observation.recognizedPoints(.thumb)
            if let thumbTipPoint = thumbPoints[.thumbTip], thumbTipPoint.confidence > MinConfidence {
                return visionCoordinatesToVideoCoordinates(thumbTipPoint)
            }
        } catch {
            print("Could not get any recognized points for hand")
            return nil
        }
        return nil
    }

    private func visionCoordinatesToVideoCoordinates(_ visionCoordinates: VNRecognizedPoint) -> CGPoint {
        return CGPoint(x: visionCoordinates.location.x, y: 1 - visionCoordinates.location.y)
    }
}
