//
//  CaptureManager.swift
//  cameraSaver
//
//  Created by Aleksandr Popov on 6/17/23.
//

import AVFoundation
import Photos

protocol CaptureManagerDelegate: AnyObject {
    func didUpdateRecordingState(isRecording: Bool)
    func didSaveVideoToPhotoLibrary(success: Bool)
}

class CaptureManager: NSObject, AVCaptureFileOutputRecordingDelegate {
    
    let captureSession = AVCaptureSession()
    var videoOutput: AVCaptureMovieFileOutput?
    var currentCamera: AVCaptureDevice?
    var currentMicrophone: AVCaptureDevice?
    var isRecording = false
    
    weak var delegate: CaptureManagerDelegate?
    
    // Implement all your setup and capture session related functions here
    // Move setupCaptureSession, setupCamera, updateMicrophoneForCamera,
    // setMicrophone, startRecording, stopRecording functions here
    
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        if let error = error {
            print("Video recording finished with error: \(error.localizedDescription)")
        } else {
            PHPhotoLibrary.shared().performChanges {
                PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: outputFileURL)
            } completionHandler: { saved, error in
                self.delegate?.didSaveVideoToPhotoLibrary(success: saved)
            }
        }
    }
}
