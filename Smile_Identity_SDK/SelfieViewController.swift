///
//  SelfieViewController.swift
//  Smile Identity Demo
//
//  Created by Janet Brumbaugh on 4/25/18.
//  Copyright © 2018 Smile Identity. All rights reserved.
//
import UIKit
import AVFoundation
import Smile_Identity_SDK
class SelfieViewController: UIViewController,
                            CaptureSelfieDelegate

{
    
    
    @IBOutlet weak var agentModeView: UIView!
    @IBAction func btnOnCickTakeAnotherSelfie(_ sender: Any) {
        agentModeView.isHidden = true
        captureSelfie?.stop()
        
        //captureSelfie = CaptureSelfie()
        tagCount = tagCount + 1
        currentTag = SmileIDSingleton.DEFAULT_USER_TAG + "_" + String( tagCount )
        captureSelfie?.setup(captureSelfieDelegate: self,
                             previewView: previewView,
                             useFrontCamera: false,
                             doFlashScreenOnShutter: doFlashScreenOnShutter )
        captureSelfie?.start( screenRect: self.view.bounds,
                              userTag: currentTag)
        
    }
    
    
    @IBAction func btnTakeAnotherSelfie(_ sender: Any) {
    }
    
    @IBOutlet weak var btnManualCapture: UIButton!
    
    @IBAction func btnManualCaptureClick(_ sender: Any) {
        captureSelfie?.manualCapture( isManualCapture: true )
    }
    
    
    @IBOutlet weak var lblPrompt        : UILabel!
    @IBOutlet weak var previewView      : VideoPreviewView!
    
    var tagCount        : Int = 0
    var currentTag      : String = SmileIDSingleton.DEFAULT_USER_TAG
    var isEnrollMode    : Bool  = false
    var hasId           : Bool  = false
    var jobType         : Int   = -1
    var isReEnroll      : Bool  = false
    var agentMode       : Bool  = false
    
    var captureSelfie                   : CaptureSelfie?
    
    var isManualCapture                 : Bool = false
    var useFrontCamera                  : Bool = true
    var doFlashScreenOnShutter          : Bool = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        lblPrompt.text = NSLocalizedString("face_state_put_face_inside_oval", comment: "")
        
        // Here is an example of how to access the max frame timeout setting.
        // The default value is 120 frames
        //        SelfieCaptureConfig.setMaxFrameTimeout( maxFrameTimeout : 200 )
        captureSelfie = CaptureSelfie()
        
        useFrontCamera = !agentMode
        doFlashScreenOnShutter = !agentMode
        
        captureSelfie?.setup(captureSelfieDelegate: self,
                             previewView: previewView,
                             useFrontCamera: useFrontCamera,
                             doFlashScreenOnShutter : doFlashScreenOnShutter)
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        /* Do position calcuations in viewDidAppear because the ui is
         layed out and the dimensions have been calculated for the
         device. In viewWillAppear the dimensions have not
         been calculated for the device yet.
         */
        
        captureSelfie?.start( screenRect: self.view.bounds,
                              userTag:currentTag )
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        guard captureSelfie != nil else {
            return;
        }
        captureSelfie!.stop()
        
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        
        if( segue.identifier == "SelfieToAuthResultSegue" ) {
            let uploadResultViewController = segue.destination as! UploadResultViewController
            uploadResultViewController.isEnrollMode = false
            uploadResultViewController.jobType = jobType
            uploadResultViewController.isReEnroll = false
        }
        else if ( segue.identifier == "SelfieToEnrollResultSegue" ){
            // Enroll mode
            let uploadResultViewController =
                segue.destination as! UploadResultViewController
            uploadResultViewController.isEnrollMode = true
            uploadResultViewController.hasId = hasId
            uploadResultViewController.isReEnroll = isReEnroll
        }
        else if ( segue.identifier == "SelfieToIDCardSegue" ){
            let cardIDViewController = segue.destination as! CardIDViewController
            cardIDViewController.isReEnroll = isReEnroll
        }
        else if ( segue.identifier == "SelfieAgentModeToEnrollResultSegue" ){
            // Enroll mode
            let uploadResultViewController =
                segue.destination as! UploadResultViewController
            uploadResultViewController.isEnrollMode = true
            uploadResultViewController.hasId = false
            uploadResultViewController.isReEnroll = false
            uploadResultViewController.isAgentMode = true
            
        }
        
    }
    
    /*
     Capture Selfie Delegate callbacks
     */
    func onError( sidError : SIDError ){
        let toastUtils = ToastUtils()
        toastUtils.showToast(view: self.view, message: sidError.message )
        
    }
    
    
    func onComplete( previewUIImage: UIImage? ) {
        let audioUtils = AudioUtils()
        audioUtils.playSound()
        
        if( isEnrollMode ){
            
            if( agentMode ){
                showRetakeSelfieView()
            }
            else {
                startEnrollMode();
            }
            
        }
        else{
            self.performSegue(
                withIdentifier: "SelfieToAuthResultSegue",
                sender: self)
        }
        
    }
    
    
    func onFaceStateChanged( faceState : Int ) {
        // logger.SIPrint(logOutput:  "updatePrompt : faceState = ", faceState )
        switch( faceState ){
        case FaceState.NO_FACE_FOUND :
            lblPrompt.text = NSLocalizedString("face_state_put_face_inside_oval", comment: "")
        case FaceState.DO_MOVE_CLOSER :
            lblPrompt.text = NSLocalizedString("face_state_move_closer", comment: "")
        case FaceState.CAPTURING :
            lblPrompt.text = NSLocalizedString("face_state_capturing", comment: "")
        case FaceState.DO_SMILE :
            if( agentMode && ( agentModeView.isHidden == true ) ) {
                btnManualCapture.isHidden = false
            }
            else{
                lblPrompt.text = NSLocalizedString("face_state_smile", comment: "")
            }
            
        default :
            lblPrompt.text = NSLocalizedString("face_state_smile", comment: "")
        } // switch
    }
    
    func showRetakeSelfieView(){
        agentModeView.isHidden = false
        btnManualCapture.isHidden = true
    }
    
    func startEnrollMode() {
        if( hasId ){
            // Go to ID Card
            self.performSegue(
                withIdentifier: "SelfieToIDCardSegue",
                sender: self)
        }
        else{
            // Go to Enroll Result
            self.performSegue(
                withIdentifier: "SelfieToEnrollResultSegue",
                sender: self)
            
        }
    }
    
    
    
    
    
    
    
    
    
    
    
}
