//
//  HandPositionController.swift
//  Theramin
//
//  Created by Andy Cho on 10/9/22.
//

import UIKit
import AVFoundation
import Vision

protocol HandPositionControllerDelegate {
    func processPoints(points: [CGPoint])
}

class HandPositionController: NSObject {
    private let MinFingertipObservationConfidence: Float = 0.3

    private let videoDataOutputQueue = DispatchQueue(label: "CameraFeedDataOutput", qos: .userInteractive)
    private var handPoseRequest = VNDetectHumanHandPoseRequest()

    public var cameraFeedSession: AVCaptureSession?
    public var delegate: HandPositionControllerDelegate?

    public func setup() {
        if cameraFeedSession == nil {
            cameraFeedSession = setupAVSession()
        }
    }

    public func start() {
        cameraFeedSession?.startRunning()
    }

    public func stop() {
        cameraFeedSession?.stopRunning()
    }

    func processPoints(points: [CGPoint]) {
        delegate?.processPoints(points: points)
    }

    private func setupAVSession() -> AVCaptureSession {
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
        return session
    }
}

extension HandPositionController: AVCaptureVideoDataOutputSampleBufferDelegate {
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
            if let indexTipPoint = indexFingerPoints[.indexTip], indexTipPoint.confidence > MinFingertipObservationConfidence {
                return visionCoordinatesToVideoCoordinates(indexTipPoint)
            }

            let thumbPoints = try observation.recognizedPoints(.thumb)
            if let thumbTipPoint = thumbPoints[.thumbTip], thumbTipPoint.confidence > MinFingertipObservationConfidence {
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
