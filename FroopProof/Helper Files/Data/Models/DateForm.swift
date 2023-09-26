//
//  DateForm.swift
//  FroopProof
//
//  Created by David Reed on 4/14/23.
//


import SwiftUI
import MapKit
import Foundation




struct DateForm {
    
    
    
    @ObservedObject var printControl = PrintControl.shared
   
    @ObservedObject var froopDataListener = FroopDataListener.shared
   
 
    
   var yyyymmdd = "yyyy-MM-dd"                              //Example: 2023-04-15
   var ddMMyyyy = "dd-MM-yyyy"                              //Example: 15-04-2023
   var MMddyyyy = "MM/dd/yyyy"                              //Example: 04/15/2023
   var ddMMyyyy2 = "dd/MM/yyyy"                             //Example: 15/04/2023
   var yyyyMMdd = "yyyy/MM/dd"                              //Example: 2023/04/15
   var yyyyMMMMdd = "yyyy MMMM dd"                          //Example: 2023 April 15
   var ddMMMMyyyy = "dd MMMM yyyy"                          //Example: 15 April 2023
   var yyyyMMMMddEEEE = "yyyy MMMM dd, EEEE"                //Example: 2023 April 15, Saturday
   var EEEEMMMMddyyyy = "EEEE, dd MMMM yyyy"                //Example: Saturday, 15 April 2023
   var MMddyyyyHHmm = "MM-dd-yyyy HH:mm"                    //Example: 04-15-2023 09:30
   var MMddyyyyhhmma = "MM/dd/yyyy hh:mm a"                 //Example: 04/15/2023 09:30 AM
   var yyyyMMddTHHmmss = "yyyy-MM-dd'T'HH:mm:ss"            //Example: 2023-04-15T09:30:45
   var yyyyMMddTHHmmssSSS = "yyyy-MM-dd'T'HH:mm:ss.SSS"     //Example: 2023-04-15T09:30:45.000
   var yyyyMMddTHHmmssSSSZ = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"   //Example: var23-04-15T09:30:45.000+0000
   var yyyyMMddTHHmmssZ = "yyyy-MM-dd'T'HH:mm:ssZ"          //Example: 2023-04-15T09:30:45+0000
   var EddMMMyyyyHHmmss = "E, dd MMM yyyy HH:mm:ss"         //Example: Sat, 15 Apr 2023 var:30:45
   var EddMMMyyyyHHmmssZ = "E, dd MMM yyyy HH:mm:ss Z"      //Example: Sat, 15 Apr 2023 var:30:45 +0000
   var MMMdhmma = "MMM d, h:mm a"                           //Example: Apr 15, 9:30 AM
   var card = "MMMM d, h:mm a"                              //Example: April 15, 9:30 AM
   var detail = "EEEE, MMM d, h:mm a"                       //Example: Saturday, Apr 15, 9:30 AM
    
    init() {}
}





