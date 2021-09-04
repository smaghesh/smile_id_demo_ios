//
//  CardIDViewController.swift
//  Smile Identity Demo
//
//  Created by Janet Brumbaugh on 4/25/18.
//  Copyright © 2018 Smile Identity. All rights reserved.
//

import UIKit
import AVFoundation
import Smile_Identity_SDK

class CardIDViewController: UIViewController,
                            CaptureIDCardDelegate {
   
    @IBOutlet weak var sIDSmartCardView: SIDSmartCardView!
    
    
    
   
    
    func onSmartCardViewFrontComplete(previewUIImage: UIImage, faceFound: Bool) {
        performSegue(withIdentifier: "CardIDToEnrollResultSegue", sender: nil)
    }
    
     func onSmartCardViewBackComplete(previewUIImage: UIImage) {
        performSegue(withIdentifier: "CardIDToEnrollResultSegue", sender: nil)
     }
    
    func onSmartCardViewError(sidError: SIDError) {
        let toastUtils = ToastUtils()
        toastUtils.showToast(view: self.view, message: sidError.message )
    }
    
    func onSmartCardViewClosed() {
        self.performSegue(withIdentifier: "unwindToSmileID", sender: self)
    }
    
    @IBAction func onClickYesButton(_ sender: Any) {
        self.performSegue(withIdentifier: "CardIDToEnrollResultSegue", sender: self)
    }
   
    
    private let FIT_ID_CARD_IN_RECT     : String = "Fit ID card inside rectangle"
    private let TAP_SCREEN_TO_CAPTURE   : String = "Tap inside screen to capture"
    private let NO_FACE_FOUND           : String = "No face found in ID card"
    private let READ_COMPLETE_ID        : String = "Can you read the complete ID?"
    private var firstTime               : Bool = true
    var isReEnroll                      : Bool?
     
    override func viewDidLoad() {
        super.viewDidLoad()
        sIDSmartCardView.setup(captureIDCardDelegate: self, userTag:SmileIDSingleton.DEFAULT_USER_TAG)
     }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    
        
        /* Unwind segue */
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Back", style: .done, target: self, action: #selector(self.backButtonPressed(sender:)))
    
        AppDelegate.AppUtility.lockOrientation(
            UIInterfaceOrientationMask.portrait, andRotateTo: UIInterfaceOrientation.portrait)
        

    }
    
  
    
 
    
    @objc func backButtonPressed(sender:UIButton) {

        /* The "unwindToSmileID" segue is defined in SmileIDViewController */
        self.performSegue(withIdentifier: "unwindToSmileID", sender: self)
    }
   
    
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
 
    func canRotate() -> Void {}
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {

        if( segue.identifier == "CardIDToEnrollResultSegue" ){
            // Enroll mode, so hasId is true and isEnrollMode is true.
            // isReEnroll can be either true or false here
            let uploadResultViewController =
                segue.destination as! UploadResultViewController
            uploadResultViewController.isEnrollMode = true
            uploadResultViewController.hasId = true;
            uploadResultViewController.isReEnroll = isReEnroll!
        }
    }
    
}
