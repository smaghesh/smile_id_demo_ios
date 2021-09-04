//
//  UploadResultViewController.swift
//  Smile Identity Demo
//
//  Created by Janet Brumbaugh on 5/21/18.
//  Copyright © 2018 Smile Identity. All rights reserved.
//

import UIKit
import Smile_Identity_SDK

class UploadResultViewController:
    UIViewController,
SIDNetworkRequestDelegate {
    @IBOutlet weak var lblAlert: UILabel!
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var lblResult: UILabel!
    @IBOutlet weak var lblConfidenceLevel: UILabel!
    @IBOutlet weak var uploadNowButton: UIButton!
    var currentTag:String?
    
    @IBAction func onClickUploadNowButton(_ sender: Any) {
        // check if network is available then start the upload
        do {
            let sidNetworkUtils = SIDNetworkUtils()
            if( sidNetworkUtils.isConnected() ){
                startActivityIndicator()
                let sidConfig = createConfig()
                
                if( isAgentMode ){
                
                    /* Here is an example of how to use the agent mode.
                        Note that there is no call to sidConfig.build.
                        That's because the sdk does a build for each of the tags, automatically.
                    */
 
                
                    if( isEnrollMode ){
                        // When using agentMode, enroll mode must be true.
                        try sidConfig.getSidNetworkRequest().submitAll(
                            sidConfig: sidConfig )
                    }
                
                }
                else {
             
                    /*  Here is an example of how to use the original way of uploading a single tag.  Notice that the call to sidConfig.build has been moved to here, instead of being called in createConfig(), like it used to be.
                     
                        Enroll mode can be true if enrolling, or false if authorizing.
                        So enroll mode does not need to be checked here.
                     */
                    sidConfig.build(
                        userTag:currentTag ?? SmileIDSingleton.DEFAULT_USER_TAG )
            
                    try sidConfig.getSidNetworkRequest().submit(
                        sidConfig: sidConfig )
                }
                
            }
            else{
                showToast( msg: "No internet connection" )
            }
        }
        catch SIDError.UNABLE_TO_BATCH_NEEDS_TO_BE_ENROLL_MODE {
            let logger = SIAppLog()
            logger.siAppPrint(logOutput: "UploadResultViewController : An error occurred while trying to upload.  Not in enroll mode." )
        }
        catch {
            let logger = SIAppLog()
            logger.siAppPrint(logOutput: "UploadResultViewController : An error occurred while trying to upload" )
        }
    }
    
    
    @IBOutlet weak var toastView: UIView!
    
    @IBOutlet weak var lblToast: UILabel!
    
    // Set to true for enroll mode.
    // Set to false for auth mode
    var isEnrollMode : Bool = false
    
    // isReEnroll is used when isEnrollMode is true.
    // It is used to re-enroll a user that was previously
    // enrolled.
    
    var isReEnroll   : Bool = false
    // mUse258 is used for auth mode
    
    // mHasId is used for enroll mode, to indicate if the user has an id card
    var hasId                           : Bool = false;
    
    var isAgentMode   : Bool = false
    
    var geoInfos                        : GeoInfos?

    static let MAX_RETRY_TIMEOUT_SEC    : Int = 15
    
    var jobType                         : Int = -1

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated )
        
        
        /*
            There is an Apple bug.  If the device orientation is already portrait ( for example, if the user has rotated the device to portrait ), then forcing it to rotate to portrait in the code won't work.
         
            But, the ui still looks like it is in landscape mode, and now it's locked.
         
            This is why the code below it is rotating to landscapeRight again, so that it forces a change, then rotating to portrait.
        */
        AppDelegate.AppUtility.lockOrientation(UIInterfaceOrientationMask.portrait, andRotateTo:
            UIInterfaceOrientation.landscapeRight)
         AppDelegate.AppUtility.lockOrientation(UIInterfaceOrientationMask.portrait, andRotateTo:
        UIInterfaceOrientation.portrait)
    
        
        
        /* Unwind segue */
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Back", style: .done, target: self, action: #selector(self.backButtonPressed(sender:)))
        
         uploadNowButton.isHidden = false
    }
    
    @objc func backButtonPressed(sender:UIButton) {
        /* The "unwindToSmileID" segue is defined in SmileIDViewController */
        self.performSegue(withIdentifier: "unwindToSmileID", sender: self)
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
      
        lblAlert?.text = ""
        stopActivityIndicator()
        
    }
    
    //Example of how to set id info
    func getIdInfo() -> SIDUserIdInfo{
        let sidId = SIDUserIdInfo()
        sidId.setIdType(idType: IdType.NATIONAL_ID)
        sidId.setIdNumber(idNumber: "12345ABC")
        return sidId
    }
    
    func createConfig() -> SIDConfig {
        
        let sidNetworkRequest = SIDNetworkRequest()
        sidNetworkRequest.setDelegate(delegate: self)
        sidNetworkRequest.initialize()
        
        let sidNetData = SIDNetData(environment: SIDNetData.Environment.PROD);
        sidNetData.setCallBackUrl(callbackUrl: "https://webhook.site/be34c93d-a91f-43db-aef2-906c5cd95d47")
    
    
        // Here is an example of how to add a custom header.
        // This will be used in the http post for the auth smile.
        // sidNetData.addAuthHeader(key: "myTestHeader", value: "myVal")
        
        let sidConfig = SIDConfig()
        sidConfig.setSidNetworkRequest( sidNetworkRequest : sidNetworkRequest )
        sidConfig.setSidNetData( sidNetData : sidNetData )
        sidConfig.setRetryOnFailurePolicy( retryOnFailurePolicy: getRetryOnFailurePolicy() )
        //Uncomment to send user id infos
        //sidConfig.setUserIdInfo(userIdInfo: getIdInfo())
        var partnerParams = PartnerParams()
        
        if( isEnrollMode ){
            sidConfig.setIsEnrollMode( isEnrollMode: true )
            sidConfig.setUseIdCard( useIdCard: hasId )
            
            if( isReEnroll ){
                partnerParams = setPartnerParamsForReEnroll(partnerParams: partnerParams)
             }
        }
        else{
            sidConfig.setIsEnrollMode( isEnrollMode : false )
            partnerParams.setJobType(jobType: jobType )
            partnerParams = setPartnerParamsForReEnroll(partnerParams: partnerParams)
        }
        
        sidConfig.setPartnerParams( partnerParams : partnerParams )
        
        return sidConfig
    }
    
    func setPartnerParamsForReEnroll( partnerParams : PartnerParams ) ->PartnerParams {
        
        // if a previous enroll has been done on the same phone
        // the user id can be accessed from SIDInfosManager.
        
        let userId = SIDInfosManager.getUserId()
        if( !userId!.isEmpty ){
            partnerParams.setUserId(userId:userId! )
        }
        
        
        
        /* Or the user id can be set directly into
            partnerParams like this.
        */
        
        // partnerParams.setUserId(userId:"previously enrolled user id" )
 
        
        return partnerParams
    }
    
    func getRetryOnFailurePolicy() -> RetryOnFailurePolicy {
        let options = RetryOnFailurePolicy();
        options.setMaxRetryTimeoutSec(maxRetryTimeoutSec: UploadResultViewController.MAX_RETRY_TIMEOUT_SEC )
        return options;
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func showToast( msg         : String ){
 
        lblAlert.text = msg
 
        _ = Timer.scheduledTimer(timeInterval: 4, target: self, selector: #selector(hideToast), userInfo: nil, repeats: false)
        
    }
    
    @objc func hideToast(){
          lblAlert.text = ""
    }
    
    func startActivityIndicator() {
        DispatchQueue.main.async {
            self.activityIndicator.isHidden = false
            self.activityIndicator.startAnimating()
        }
    }
    
    func stopActivityIndicator() {
        DispatchQueue.main.async {
            self.activityIndicator.stopAnimating()
            self.activityIndicator.isHidden = true
        }
        
    }
    
    
    /*
     SIDNetworkRequestDelegate calls
    */
    func onComplete() {
        stopActivityIndicator()
        if( isEnrollMode ){
            showToast( msg: "Job Complete" )
        }
    }
    
    
    func onError(sidError: SIDError) {
        stopActivityIndicator()
        showToast( msg: sidError.message )
    }
    
    
    func updateUI( resultText : String,
                   confidenceText : String,
                   color : UIColor ) {
        stopActivityIndicator()
        
        lblResult.textColor = color
        lblResult.text = resultText
        
        lblConfidenceLevel.text = confidenceText
   
        uploadNowButton.isHidden = true
      
    }
    
    func onAuthenticated( sidResponse : SIDResponse ) {
    
        var resultText      : String?
        
        var color : UIColor?
        
        let confidenceValue = sidResponse.getConfidenceValue()
        var confidenceText = ""
        
        if( sidResponse.isSuccess() ){
            color = UIColor.green
            resultText = "VERIFIED"
            if( confidenceValue > 5 ){
                confidenceText = "Confidence Value " + String(confidenceValue) + "%"
            }
        }
        else{
            color = UIColor.red
            resultText = "NOT VERIFIED"
        }
        updateUI(resultText: resultText!, confidenceText: confidenceText, color : color! )
  
    }
    
    func onEnrolled( sidResponse : SIDResponse ) {
        var resultText : String?
        var color : UIColor?
        
        let confidenceValue = sidResponse.getConfidenceValue()
        let testing = sidResponse.getStatusResponse()?.getJobStatusRequest()
        print( "job status start")
        dump(testing)
        print( "job status end")
        
        var confidenceText = ""
        if( sidResponse.isSuccess() ){
            color = UIColor.green
            resultText = "ENROLLED UPLOADED SUCCESSFULLY"
            if( confidenceValue > 5 ){
                confidenceText = "Confidence Value " + String(confidenceValue) + "%"
            }
        }
        else{
            color = UIColor.red
            resultText = "ENROLL FAILED"
        }
        updateUI(resultText: resultText!, confidenceText: confidenceText, color : color! )
        
        /*
         // Here is an example of how to get the PartnerParams object returned in sidResponse
        let partnerParams = sidResponse.getPartnerParams()
        let userId = partnerParams?.getUserId()
        let jobId = partnerParams?.getJobId()
        let jobType = partnerParams?.getJobType()
        let myAdditionalValue = partnerParams?.getAdditionalValue( key: "MyKey" )
        
        
        print( "Returned Partner Params" )
        if( userId != nil ){
            print( "userId = " + userId! )
        }
        else{
            print( "userId = nil" )
        }
    
        if( jobId != nil ){
            print( "jobId = " + jobId! )
        }
        else{
            print( "jobId = nil" )
        }
        
        if( jobType != nil ){
            print( "jobType = " + String(jobType!) )
        }
        else{
            print( "jobType = nil" )
        }
        
        if( myAdditionalValue != nil ){
            // for example, if the additionalValue is an Int
            print( "myAdditionalValue = " + String(myAdditionalValue! as! Int)  )
        }
        else{
            print( "myAdditionalValue = nil" )
        }
        */
        
    }
    
    func onStartJobStatus() {}
    func onEndJobStatus() {}
    func onUpdateJobProgress( progress : Int ) {}
    func onUpdateJobStatus( msg : String ) {
        /*
        let logger = SIAppLog()
        siAppPrint( msg )
        */
    }
    func onIdValidated(idValidationResponse: IDValidationResponse) {
    }
    
    
    
 
}
