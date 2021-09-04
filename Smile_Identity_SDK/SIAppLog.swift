//
//  SIAppLog.swift
//  Smile Identity Demo
//
//  Created by Janet Brumbaugh on 8/1/18.
//  Copyright © 2018 Smile Identity. All rights reserved.
//

import Foundation
class SIAppLog {
    
    func siAppPrint( logOutput : String ){
        
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd/yy HH:mm:ss.SSS"
        let date = Date()
        let dateString = formatter.string(from: date)
        
        print( dateString, ": ", logOutput )
    }
}
