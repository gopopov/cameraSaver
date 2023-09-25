`//
//  ContentView.swift
//  cameraSaver
//
//  Created by Aleksandr Popov on 5/24/23.


import AVFoundation
import UIKit
import Photos

class ViewController: UIViewController, AVCaptureFileOutputRecordingDelegate {
    
    let captureSession = AVCaptureSession()
    var videoOutput: AVCaptureMovieFileOutput?
    var currentCamera: AVCaptureDevice?
    var currentMicrophone: AVCaptureDevice?
    var isRecording = false
    var currentCameraIndex = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        DispatchQueue.global(qos: .userInitiated).async {
            self.setupCaptureSession()
            self.setupCamera()
            DispatchQueue.main.async {
                self.setupPreviewLayer()
                self.updateUI()
                DispatchQueue.global(qos: .userInitiated).async {
                    self.captureSession.startRunning()
                }
            }
        }

    }

    
    func setupCaptureSession() {
        captureSession.beginConfiguration()
        captureSession.sessionPreset = .hd1920x1080
        
        guard let videoDevice = AVCaptureDevice.default(for: .video) else {
            print("Failed to get the camera device")
            return
        }
        
        guard let audioDevice = AVCaptureDevice.default(for: .audio) else {
            print("Failed to get the audio device")
            return
        }
        
        do {
            let videoInput = try AVCaptureDeviceInput(device: videoDevice)
            if captureSession.canAddInput(videoInput) {
                captureSession.addInput(videoInput)
            }
            
            let audioInput = try AVCaptureDeviceInput(device: audioDevice)
            if captureSession.canAddInput(audioInput) {
                captureSession.addInput(audioInput)
            }
            
            videoOutput = AVCaptureMovieFileOutput()
            if captureSession.canAddOutput(videoOutput!) {
                captureSession.addOutput(videoOutput!)
            }
            
            captureSession.commitConfiguration()
        } catch {
            print("Failed to initialize input devices: \(error.localizedDescription)")
        }
    }
//    Set up Camera
    func setupCamera() {
        for device in AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: .video, position: .unspecified).devices {
            if device.position == .back {
                currentCamera = device
                break
            }
        }
    }
    
    func setMicrophone(microphone: AVCaptureDevice) {
        captureSession.beginConfiguration()

        // Remove all current audio inputs
        for input in captureSession.inputs {
            if let deviceInput = input as? AVCaptureDeviceInput, deviceInput.device.hasMediaType(.audio) {
                captureSession.removeInput(deviceInput)
            }
        }

        // Add the new microphone as an input
        do {
            let audioInput = try AVCaptureDeviceInput(device: microphone)
            if captureSession.canAddInput(audioInput) {
                captureSession.addInput(audioInput)
            }
        } catch {
            print("Failed to set microphone: \(error.localizedDescription)")
        }

        captureSession.commitConfiguration()
    }
    
    func updateMicrophoneForCamera(cameraPosition: AVCaptureDevice.Position) {
        let discoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInMicrophone], mediaType: .audio, position: .unspecified)
        
        // Prefer first microphone in the list (which should be the external one if connected)
        var preferredMic = discoverySession.devices.first
        
        // If using front camera, prefer the microphone that has the same position as the camera
        if cameraPosition == .front, let frontMic = discoverySession.devices.first(where: { $0.position == .front }) {
            preferredMic = frontMic
        }
        
        // Add selected microphone as input
        if let preferredMic = preferredMic {
            setMicrophone(microphone: preferredMic)
        }
    }

    
    func setupPreviewLayer() {
        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.frame = view.bounds
        view.layer.insertSublayer(previewLayer, at: 0)
        
        // Adding the camera switch button programmatically
        let switchCameraButton = UIButton(frame: CGRect(x: 20, y: 80, width: 120, height: 40))
        switchCameraButton.setTitle("Camera", for: .normal)
        switchCameraButton.addTarget(self, action: #selector(switchCameraTapped), for: .touchUpInside)
        view.addSubview(switchCameraButton)
        
        // Adding the start recording button programmatically
        let buttonWidth: CGFloat = 200
        let buttonHeight: CGFloat = 60
        let StarRecordingButton = UIButton(frame: CGRect(x: (view.frame.width - buttonWidth) / 2, y: view.frame.height - buttonHeight - 20, width: buttonWidth, height: buttonHeight))
           StarRecordingButton.setTitle("Start Recording", for: .normal)
           StarRecordingButton.addTarget(self, action: #selector(startRecordingTapped), for: .touchUpInside)
           StarRecordingButton.layer.cornerRadius = 10
           StarRecordingButton.clipsToBounds = true
           view.addSubview(StarRecordingButton)
        
        DispatchQueue.global(qos: .userInitiated).async {
            self.captureSession.startRunning()
        }
    }

    @objc func switchCameraTapped(_ sender: UIButton) {
        print("Switch Camera button tapped!")
        
        // Get a list of all video devices (cameras)
        let cameras = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera, .builtInTelephotoCamera, .builtInUltraWideCamera, .builtInDualCamera], mediaType: .video, position: .unspecified).devices
        
        guard !cameras.isEmpty else {
            print("No cameras available")
            return
        }
        
        captureSession.beginConfiguration()
        
        // Find the next camera index
        currentCameraIndex = (currentCameraIndex + 1) % cameras.count
        
        // Get the next camera
        let nextCamera = cameras[currentCameraIndex]
        
        // Remove all current video inputs
        for input in captureSession.inputs {
            if let deviceInput = input as? AVCaptureDeviceInput, deviceInput.device.hasMediaType(.video) {
                captureSession.removeInput(deviceInput)
            }
        }
        
        // Add the input of the next camera
        do {
            let newInput = try AVCaptureDeviceInput(device: nextCamera)
            if captureSession.canAddInput(newInput) {
                captureSession.addInput(newInput)
                currentCamera = nextCamera
            }
        } catch {
            print("Failed to switch camera: \(error.localizedDescription)")
        }
        
        // Update the microphone based on the new camera
        updateMicrophoneForCamera(cameraPosition: nextCamera.position)
        
        captureSession.commitConfiguration()
    }

    
// Objective C startRecording
    
    @objc func startRecordingTapped(_ sender: UIButton) {

        print("Start Recording button tapped!")
        
        if isRecording {
            stopRecording()
        } else {
            startRecording()
        }
    }
    
    func startRecording() {
        DispatchQueue.main.async { [self] in
            guard let fileOutput = self.videoOutput else {
                return
            }
            
            let fileManager = FileManager.default
            let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let videoOutputURL = documentsURL.appendingPathComponent("video_output.mov")
            
            fileOutput.startRecording(to: videoOutputURL, recordingDelegate: self)
            
            self.isRecording = true
            self.updateUI()
        }
    }
    
    func stopRecording() {
        DispatchQueue.main.async {
            self.videoOutput?.stopRecording()
            
            self.isRecording = false
            self.updateUI()
        }
    }
    
    func updateUI() {
        DispatchQueue.main.async {
                guard let startRecordingButton = self.view.subviews.compactMap({ $0 as? UIButton }).first(where: { $0.currentTitle?.contains("Recording") == true || $0.currentTitle == "Start Recording" }) else {
                    return
                }
            
                if self.isRecording {
                    startRecordingButton.setTitle("Recording", for: .normal)
                    startRecordingButton.backgroundColor = .red
                } else {
                    startRecordingButton.setTitle("Start Recording", for: .normal)
                    startRecordingButton.backgroundColor = .green
                }
            }
    }
    
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        if let error = error {
            print("Video recording finished with error: \(error.localizedDescription)")
        } else {
            PHPhotoLibrary.shared().performChanges {
                PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: outputFileURL)
            } completionHandler: { saved, error in
                if saved {
                    print("Video saved to photo library.")
                } else {
                    print("Failed to save video to photo library: \(error?.localizedDescription ?? "")")
                }
            }
        }
    }
}
`
