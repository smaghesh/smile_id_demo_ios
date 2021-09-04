//
//  SmileIDViewController.swift
//  Smile Identity Demo
//
//  Created by Janet Brumbaugh on 4/25/18.
//  Copyright © 2018 Smile Identity. All rights reserved.
//

import UIKit
import MapKit
import Smile_Identity_SDK

class SmileIDViewController: UIViewController, CLLocationManagerDelegate,SIDCaptureManagerDelegate {
    
    
  
    
    /* This defines the "unwindToSmileID" unwind segue */
    @IBAction func unwindToSmileID( _sender:UIStoryboardSegue ){
        // print( "unwindToSmileID" )
    }
    
    var locationManager         : CLLocationManager!
    var currentLocation         : CLLocation?
    var captureType              : CaptureType?
    var currentTag : String?
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated )
        
        
        /*
         Make sure this controller's orientation is portrait, regardless
         how this controller is navigated to.
         
         
         There is an Apple bug.  If the device orientation is already portrait ( for example, if the user has rotated the device to portrait ), then forcing it to rotate to portrait in the code won't work.
         
         But, the ui still looks like it is in landscape mode, and now it's locked.
         
         This is why the code below it is rotating to landscapeRight again, so that it forces a change, then rotating to portrait.
         */
        AppDelegate.AppUtility.lockOrientation(UIInterfaceOrientationMask.portrait, andRotateTo:
            UIInterfaceOrientation.landscapeRight)
        AppDelegate.AppUtility.lockOrientation(UIInterfaceOrientationMask.portrait, andRotateTo:
            UIInterfaceOrientation.portrait)
        
        
    
    }
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let sidNetData = SIDNetData(environment: SIDNetData.Environment.TEST);
        
        locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        // locationManager.requestAlwaysAuthorization()
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        
        //Looks for single or multiple taps.
        //Looks for single or multiple taps.
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(SmileIDViewController.dismissKeyboard))
        view.addGestureRecognizer(tap)

    }
 

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Nothing is passed through for the SIDAuthUsingSavedDataSegue
        if( segue.identifier == "smileUIEnroll" ) {
            let uploadResultViewController =
                segue.destination as! UploadResultViewController
            uploadResultViewController.isEnrollMode = true
            uploadResultViewController.hasId = false
            uploadResultViewController.isReEnroll = false
            uploadResultViewController.currentTag = currentTag
        }
        else if ( segue.identifier == "smileUIEnrollWID" ){
            // Enroll mode
            let uploadResultViewController =
                segue.destination as! UploadResultViewController
            uploadResultViewController.isEnrollMode = true
            uploadResultViewController.hasId = true
            uploadResultViewController.isReEnroll = false
            uploadResultViewController.currentTag = currentTag
        } else if( segue.identifier == "SIDAuthUsingSavedDataSegue" ){
            
            let uploadResultViewController = segue.destination as! UploadResultViewController
            uploadResultViewController.isEnrollMode = false
           
            // has id is only used when the uploadResultController is used for enroll
            uploadResultViewController.hasId = false
        }
        else {
            let nextController = segue.destination
            if nextController is SelfieViewController{
                let selfieViewController = segue.destination as! SelfieViewController
                var isEnrollMode    : Bool = false
                var hasId           : Bool = false
                var isReEnroll      : Bool = false
                var agentMode       : Bool = false
                
                if( segue.identifier == "SIDEnrollSegue" ) {
                    isEnrollMode = true
                    hasId = true
                    isReEnroll = false
                }
                else if( segue.identifier == "SIDEnrollNoIDSegue" ){
                    isEnrollMode = true
                    hasId = false
                    isReEnroll = false
                }
                else if( segue.identifier == "SIDAuthSegue" ){
                    isEnrollMode = false
                }
                else if( segue.identifier == "SIDReEnrollSegue" ){
                    isEnrollMode = true;
                    hasId = false;
                    isReEnroll = true
                }
                else if( segue.identifier == "SIDReEnrollWithIDSegue" ){
                    isReEnroll = true
                    isEnrollMode = true
                    hasId = true
                }
                else if( segue.identifier == "UpdateEnrolledImageSegue" ){
                    selfieViewController.jobType = 8
                }
                else if( segue.identifier == "AgentModeSegue" ){
                    isEnrollMode = true
                    agentMode = true
                }
                
                
                selfieViewController.isEnrollMode = isEnrollMode;
                selfieViewController.hasId = hasId
                selfieViewController.isReEnroll = isReEnroll
                selfieViewController.agentMode = agentMode
            }
        }
    }
    
    
    
    // Callback for when location changes
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        locationManager.stopUpdatingLocation()
        currentLocation = locations[0]
        // TEST for debugging
        let latitude = (currentLocation?.coordinate.latitude)!
        let longitude = (currentLocation?.coordinate.longitude)!
        let altitude = (currentLocation?.altitude)!
        let time = DateTimeUtils().getCurrentDateTime()

 

        SmileIDSingleton.sharedInstance.geoInfos = GeoInfos(latitude: latitude, longitude: longitude, altitude: altitude, accuracy: kCLLocationAccuracyBest, lastUpdate: time)
        }
        

    
    

    
    //Calls this function when the tap is recognized.
    @objc func dismissKeyboard() {
        //Causes the view (or one of its embedded text fields) to resign the first responder status.
        view.endEditing(true)
    }
    
    func onSuccess(tag: String, selfiePreview: UIImage?, idFrontPreview: UIImage?, idBackPreview: UIImage?) {
        currentTag = tag
        if (captureType == CaptureType.SELFIE){
            self.performSegue(
                withIdentifier: "smileUIEnroll",
                sender: self)
        }else{
            self.performSegue(
                withIdentifier: "smileUIEnrollWID",
                sender: self)
        }
        
    }
    
    
    
    func onError(tag: String, sidError: SIDError) {
        
    }
 
    @IBAction func smileUIEnrollWithID(_ sender: Any) {
        captureType = CaptureType.SELFIE_AND_ID_CAPTURE
        let builder = SIDCaptureManager.Builder(delegate: self, captureType: CaptureType.SELFIE_AND_ID_CAPTURE)
        let sidIdCaptureConfig = SIDIDCaptureConfig.Builder().setIdCaptureType(idCaptureType: IDCaptureType.Front_And_Back).build()
        builder.setSidIdCaptureConfig(sidIdCaptureConfig: sidIdCaptureConfig!).build().start()
    }
    
    @IBAction func smileUIEnroll(_ sender: Any) {
        captureType = CaptureType.SELFIE
        SIDCaptureManager.Builder(delegate: self, captureType: CaptureType.SELFIE).build().start()
    }
}
