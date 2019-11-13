//
//  ViewController.swift
//  Guided Camera
//
//  Created by zawyenaing on 2018/10/01.
//  Copyright © 2018 swift.test. All rights reserved.
//

import UIKit
import AVFoundation
import Foundation

extension UIImageView {
    func roundCorners(_ corners:UIRectCorner, radius: CGFloat) {
        let path = UIBezierPath(roundedRect: self.bounds, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        let mask = CAShapeLayer()
        mask.path = path.cgPath
        self.layer.mask = mask
    }
}

class CameraViewController: UIViewController, AVCapturePhotoCaptureDelegate {
    
    
    @IBOutlet weak var previewView: UIView!
    @IBOutlet weak var capturedImageView: UIImageView!
    @IBOutlet weak var cameraActionView: UIView!
    @IBOutlet weak var choosePhotoActionView: UIView!
    
    @IBOutlet weak var photoSaveButton: UIButton!
    @IBOutlet weak var photoCancelButton: UIButton!
    @IBOutlet weak var cameraButton: UIButton!
    
    fileprivate var referenceFrameImageView = UIImageView() // Reference before taking picture
    var croppedImageView = UIImageView() //For the preview
    var cropImageRect: CGRect {
        return referenceFrameImageView.frame
    }
    var cropImageRectCorner = UIRectCorner()
    
    var captureSession: AVCaptureSession!
    var stillImageOutput: AVCapturePhotoOutput!
    var videoPreviewLayer: AVCaptureVideoPreviewLayer!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationController?.navigationBar.barTintColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)
        self.navigationController?.navigationBar.titleTextAttributes = [NSAttributedStringKey.foregroundColor: #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)]
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        captureSession = AVCaptureSession()
        captureSession.sessionPreset = .high
        guard let backCamera = AVCaptureDevice.default(for: AVMediaType.video)
            else {
                print("Unable to access back camera")
                return
        }
        do {
            let input = try AVCaptureDeviceInput(device: backCamera)
            stillImageOutput = AVCapturePhotoOutput()
            stillImageOutput.isHighResolutionCaptureEnabled = true
            
            if captureSession.canAddInput(input) && captureSession.canAddOutput(stillImageOutput) {
                captureSession.addInput(input)
                captureSession.addOutput(stillImageOutput)
                setupCameraPreview()
            }
        }
        catch let error  {
            print("Error Unable to initialize back camera:  \(error.localizedDescription)")
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.captureSession.stopRunning()
    }
    
    func setupCameraPreview() {
        
        referenceFrameImageView = setupGuideLineArea()
        referenceFrameImageView.translatesAutoresizingMaskIntoConstraints = false
        referenceFrameImageView.heightAnchor.constraint(equalToConstant: 200).isActive = true
        referenceFrameImageView.widthAnchor.constraint(equalToConstant: 300).isActive = true
        
        videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        videoPreviewLayer.videoGravity = .resizeAspectFill
        videoPreviewLayer.connection?.videoOrientation = .portrait
        previewView.layer.addSublayer(videoPreviewLayer)
        previewView.addSubview(referenceFrameImageView)
        referenceFrameImageView.centerYAnchor.constraint(equalTo: previewView.centerYAnchor).isActive = true
        referenceFrameImageView.centerXAnchor.constraint(equalTo: previewView.centerXAnchor).isActive = true
            
        DispatchQueue.global(qos: .userInitiated).async {
            self.captureSession.startRunning()
            DispatchQueue.main.async {
                self.videoPreviewLayer.frame = self.previewView.bounds
            }
        }
    }
    
    func setRotation() {
        let deviceOrientation = UIDevice.current.orientation
        
        let photoOutputConnection = stillImageOutput.connection(with:AVMediaType.video)
            
    
        switch deviceOrientation {
        case .landscapeLeft:
            videoPreviewLayer?.connection?.videoOrientation = AVCaptureVideoOrientation.landscapeRight
            photoOutputConnection?.videoOrientation = AVCaptureVideoOrientation.landscapeRight
            break
        case .landscapeRight:
            videoPreviewLayer?.connection?.videoOrientation = AVCaptureVideoOrientation.landscapeLeft
            photoOutputConnection?.videoOrientation = AVCaptureVideoOrientation.landscapeLeft
            break
        case .portrait:
            videoPreviewLayer?.connection?.videoOrientation = AVCaptureVideoOrientation.portrait
            photoOutputConnection?.videoOrientation = AVCaptureVideoOrientation.portrait
            break
        case .portraitUpsideDown:
            videoPreviewLayer?.connection?.videoOrientation = AVCaptureVideoOrientation.portraitUpsideDown
            photoOutputConnection?.videoOrientation = AVCaptureVideoOrientation.portraitUpsideDown
            break
        default:
            break
        }
    }
    
    func setupGuideLineArea() -> UIImageView {
        let edgeInsets:UIEdgeInsets = UIEdgeInsets.init(top: 22, left: 22, bottom: 22, right: 22)
        let resizableImage = (UIImage(named: "guideImage")?.resizableImage(withCapInsets: edgeInsets, resizingMode: .stretch))!
        cropImageRectCorner = [.allCorners]
        let imageView = UIImageView(image: resizableImage)
        return imageView
    }
    
    func previewViewLayerMode(image: UIImage?, isCameraMode: Bool) {
        if isCameraMode {
            self.captureSession.startRunning()
            
            cameraActionView.isHidden = false
            choosePhotoActionView.isHidden = true
            
            previewView.isHidden = false
            capturedImageView.isHidden = true
        } else {
            self.captureSession.stopRunning()
            cameraActionView.isHidden = true
            choosePhotoActionView.isHidden = false
            
            previewView.isHidden = true
            capturedImageView.isHidden = false
            
            // Original image to blureffect
            let blurEffect = UIBlurEffect(style: .light)
            let blurView = UIVisualEffectView(effect: blurEffect)
            blurView.translatesAutoresizingMaskIntoConstraints = false
            capturedImageView.addSubview(blurView)
            blurView.widthAnchor.constraint(equalTo: capturedImageView.widthAnchor).isActive = true
            blurView.heightAnchor.constraint(equalTo: capturedImageView.heightAnchor).isActive = true
            blurView.centerXAnchor.constraint(equalTo: capturedImageView.centerXAnchor).isActive = true
            blurView.centerYAnchor.constraint(equalTo: capturedImageView.centerYAnchor).isActive = true

            
            // Crop guide Image
            croppedImageView = UIImageView(image: image!)
            croppedImageView.translatesAutoresizingMaskIntoConstraints = false
            capturedImageView.addSubview(croppedImageView)
            croppedImageView.centerYAnchor.constraint(equalTo: referenceFrameImageView.centerYAnchor).isActive = true
            croppedImageView.centerXAnchor.constraint(equalTo: referenceFrameImageView.centerXAnchor).isActive = true
            croppedImageView.widthAnchor.constraint(equalTo: referenceFrameImageView.widthAnchor).isActive = true
            croppedImageView.heightAnchor.constraint(equalTo: referenceFrameImageView.heightAnchor).isActive = true
            croppedImageView.frame = cropImageRect
            croppedImageView.roundCorners(cropImageRectCorner, radius: 10)
        }
    }
    
    // MARK: - AVCapturePhotoCaptureDelegate
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        
        guard error == nil else {
            print("Fail to capture photo: \(String(describing: error))")
            return
        }
        
        // Check if the pixel buffer could be converted to image data
        guard let imageData = photo.fileDataRepresentation() else {
            print("Fail to convert pixel buffer")
            return
        }

        let orgImage : UIImage = UIImage(data: imageData)!
        capturedImageView.image = orgImage
        capturedImageView.backgroundColor = UIColor.red
        capturedImageView.contentMode = .scaleAspectFill
        let originalSize: CGSize
        let visibleLayerFrame = cropImageRect
        
        // Calculate the fractional size that is shown in the preview
        let metaRect = (videoPreviewLayer?.metadataOutputRectConverted(fromLayerRect: visibleLayerFrame )) ?? CGRect.zero
        
        if (orgImage.imageOrientation == UIImageOrientation.left || orgImage.imageOrientation == UIImageOrientation.right) {
            originalSize = CGSize(width: orgImage.size.height, height: orgImage.size.width)
        } else {
            originalSize = orgImage.size
        }
        let cropRect: CGRect = CGRect(x: metaRect.origin.x * originalSize.width, y: metaRect.origin.y * originalSize.height, width: metaRect.size.width * originalSize.width, height: metaRect.size.height * originalSize.height).integral
        
        if let finalCgImage = orgImage.cgImage?.cropping(to: cropRect) {
            let image = UIImage(cgImage: finalCgImage, scale: 1.0, orientation: orgImage.imageOrientation)
            previewViewLayerMode(image: image, isCameraMode: false)
        }
    }
    
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        DispatchQueue.main.async {
            self.videoPreviewLayer.frame = self.previewView.bounds
            self.setRotation()
        }
    }
    
    // MARK: - @IBAction
    @IBAction func actionCameraCapture(_ sender: AnyObject) {
        
        // Istance of AVCapturePhotoSettings class
        var photoSettings: AVCapturePhotoSettings
        
        photoSettings = AVCapturePhotoSettings.init(format: [AVVideoCodecKey: AVVideoCodecType.jpeg])
        photoSettings.isAutoStillImageStabilizationEnabled = true
        photoSettings.isHighResolutionPhotoEnabled = true
        photoSettings.flashMode = .auto
        
    
        // AVCapturePhotoCaptureDelegate
        stillImageOutput.capturePhoto(with: photoSettings, delegate: self)
    }
    
    @IBAction func savePhotoPressed(_ sender: Any) {
        
        UIImageWriteToSavedPhotosAlbum(croppedImageView.image!, self, #selector(image(_:didFinishSavingWithError:contextInfo:)), nil)
    }
    
    @objc func image(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        if let error = error {
            
            let alertController = UIAlertController(title: "Save Error", message: error.localizedDescription, preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: { (alert: UIAlertAction!) in
                self.previewViewLayerMode(image: nil, isCameraMode: true)
            }))
            present(alertController, animated: true)
        } else {
            let alertController = UIAlertController(title: "Saved", message: "Captured guided image saved successfully.", preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: { (alert: UIAlertAction!) in
                self.previewViewLayerMode(image: nil, isCameraMode: true)
            }))
            present(alertController, animated: true)
        }
    }
    
    @IBAction func cancelPhotoPressed(_ sender: Any) {
        
        previewViewLayerMode(image: nil, isCameraMode: true)
    }
    
}

