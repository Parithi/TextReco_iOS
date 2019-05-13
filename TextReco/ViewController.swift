//
//  ViewController.swift
//  TextReco
//
//  Created by ElamParithi Arul on 2019-05-12.
//  Copyright © 2019 Parithi Network. All rights reserved.
//

import UIKit
import AVFoundation
import Firebase

class ViewController: UIViewController {

    @IBOutlet weak var cameraView: UIView!
    @IBOutlet weak var previewView: UIImageView!
    @IBOutlet weak var messageView: UILabel!
    @IBOutlet weak var actionButton: UIButton!
    
    
    var captureSession: AVCaptureSession!
    var stillImageOutput: AVCapturePhotoOutput!
    var videoPreviewLayer: AVCaptureVideoPreviewLayer!
    var isImageCaptured = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        setupCamera()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        stopCamera()
    }
    
    func setupCamera() {
        captureSession = AVCaptureSession()
        captureSession.sessionPreset = .medium
        
        guard let backCamera = AVCaptureDevice.default(for: AVMediaType.video) else {
            print("Unable to access back camera!")
            return
        }
        
        do {
            let input = try AVCaptureDeviceInput(device: backCamera)
            stillImageOutput = AVCapturePhotoOutput()
            
            if captureSession.canAddInput(input) && captureSession.canAddOutput(stillImageOutput) {
                captureSession.addInput(input)
                captureSession.addOutput(stillImageOutput)
                setupLivePreview()
            }
            
            startCamera()
            
        }
        catch let error  {
            print("Error Unable to initialize back camera:  \(error.localizedDescription)")
        }
    }
    
    func startCamera() {
        DispatchQueue.global(qos: .userInitiated).async {
            self.captureSession.startRunning()
            
        }
        
        DispatchQueue.main.async {
            self.videoPreviewLayer.frame = self.cameraView.frame
        }
    }
    
    func stopCamera() {
        self.captureSession.stopRunning()
    }
    
    func setupLivePreview() {
        videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        videoPreviewLayer.videoGravity = .resizeAspectFill
        videoPreviewLayer.connection?.videoOrientation = .portrait
        cameraView.layer.addSublayer(videoPreviewLayer)
    }

    @IBAction func actionClicked(_ sender: Any) {
        if(isImageCaptured) {
            resetCamera()
        } else {
            let settings = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.jpeg])
            stillImageOutput.capturePhoto(with: settings, delegate: self)
            isImageCaptured = true
        }
    }
    
    func resetCamera() {
        previewView.isHidden = true
        messageView.text = "Click capture to get started"
        actionButton.setTitle("CAPTURE", for: .normal)
        isImageCaptured = false
        startCamera()
    }
}

extension ViewController : AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        
        guard let imageData = photo.fileDataRepresentation()
            else { return }
        
        let image = UIImage(data: imageData)!
        processImage(image: image)
        previewView.image = image
        previewView.isHidden = false
        stopCamera()
    }
    
    func processImage(image : UIImage) {
        messageView.text = "Processing.."
        let vision = Vision.vision()
        let textRecognizer = vision.onDeviceTextRecognizer()
        let imageToRecognize = VisionImage(image: image)
        actionButton.setTitle("RESET", for: .normal)

        let metadata = VisionImageMetadata()
        let devicePosition: AVCaptureDevice.Position = .back
        let deviceOrientation = UIDevice.current.orientation
        switch deviceOrientation {
        case .portrait:
            metadata.orientation = devicePosition == .front ? .leftTop : .rightTop
        case .landscapeLeft:
            metadata.orientation = devicePosition == .front ? .bottomLeft : .topLeft
        case .portraitUpsideDown:
            metadata.orientation = devicePosition == .front ? .rightBottom : .leftBottom
        case .landscapeRight:
            metadata.orientation = devicePosition == .front ? .topRight : .bottomRight
        case .faceDown, .faceUp, .unknown:
            metadata.orientation = .leftTop
        @unknown default:
            metadata.orientation = .leftTop
        }
        
        imageToRecognize.metadata = metadata
        
        textRecognizer.process(imageToRecognize) { result, error in
            guard error == nil, let result = result else {
                self.messageView.text = "Error recognizing data"
                print(error.debugDescription)
                return
            }
            
            if(result.text.count > 0) {
                print("here")
                self.messageView.text = result.text
            } else {
                self.messageView.text = "Unable to recognize data"
            }
        }
    }
}

