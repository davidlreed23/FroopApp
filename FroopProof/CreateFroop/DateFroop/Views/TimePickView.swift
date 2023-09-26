//
//  TimePickView.swift
//  FroopProof
//
//  Created by David Reed on 1/25/23.
//

import SwiftUI
import UIKit
import Foundation
import FirebaseAuth


struct TimePickView: View {
    @Environment(\.colorScheme) var colorScheme

    @ObservedObject var printControl = PrintControl.shared
    @ObservedObject var appStateManager = AppStateManager.shared
    @ObservedObject var froopDataListener = FroopDataListener.shared
    @ObservedObject var myData = MyData.shared
    
    @State var dHour = "01"
    @State var dMinute = "00"
    @State var hour = "" 
    @State var minute = ""
    @State var isPM = false
    @State var dayNight: Bool = true
    
    @Binding var transClock: Bool
    @Binding var datePicked: Bool
    @Binding var  duraVis: Bool
    @ObservedObject var froopData: FroopData
    @ObservedObject var changeView: ChangeView

    let sourceTimeZone = TimeZone(identifier: "UTC")!

    let cal = Calendar.current
    let dateFormatter = DateFormatter()
    var dateString: String {
        dateFormatter.dateFormat = "MMMM yyyy"
        return dateFormatter.string(from: self.froopData.froopStartTime)
    }

    var selectedDateString: String {
        dateFormatter.dateFormat = "MMMM dd, yyyy"
        return dateFormatter.string(from: self.froopData.froopStartTime)
    }

    
    var body: some View {
        
        
        ZStack(alignment: .topLeading) {
            VStack{
                ZStack (alignment: .top){
                    VStack {
                        TimeEnterView(dayNight: $dayNight, transClock: $transClock, hour: $hour, minute: $minute, isPM: $isPM)
                        
                        DurationEnterView(dHour: $dHour, dMinute: $dMinute)
                            .offset(y: -30)
                    }
                    .offset(y: -50)
                    Spacer()
                }
                //MARK: Button
                ZStack {
                    Rectangle()
                        .frame(height: transClock ? 125 : 1, alignment: .bottom)
                        .foregroundColor(colorScheme == .dark ? .black : .black)
                        .opacity(0.8)
                        .ignoresSafeArea()
                        .offset(y: -30)
                    //.padding(.top)
                    Button {
                        froopData.froopHost = FirebaseServices.shared.uid
                        updateFroopDuration()
                        updateFroopStartTime()
                        if appStateManager.froopIsEditing {
                            changeView.pageNumber = 5
                        } else {
                            changeView.pageNumber += 1
                        }
                    } label: {
                        Text("Confirm!")
                            .font(.system(size: 32, weight: .thin))
                            .foregroundColor(colorScheme == .dark ? .white : .white)                             .multilineTextAlignment(.center)
                            .frame(width: 250, height: 45)
                            .border(Color.gray, width: 1)
                    }
                    .offset(y: -60)
                }
            }
            
            .opacity(transClock ? 1 : 0)
            
        }
        .ignoresSafeArea(.keyboard)
        .frame(minWidth: 0,maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
        //.ignoresSafeArea()
    }
    func calculateDuration(startTime: Date, endTime: Date) -> (hours: Int, minutes: Int, seconds: Int) {
        PrintControl.shared.printTime("-TimePickView: Function: calculateDuration is firing")
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute, .second], from: startTime, to: endTime)
        return (components.hour ?? 0, components.minute ?? 0, components.second ?? 0)
    }
    
    func convertToLocalTime(date: Date) -> Date {
        PrintControl.shared.printTime("-TimePickView: Function: convertToLocalTime is firing")
        let sourceTimeZone = TimeZone(identifier: "UTC")!
        let destinationTimeZone = TimeZone.current
        
        let sourceOffset = sourceTimeZone.secondsFromGMT(for: date)
        let destinationOffset = destinationTimeZone.secondsFromGMT(for: date)
        let interval = TimeInterval(destinationOffset - sourceOffset)
        
        return date.addingTimeInterval(interval)
    }
    
    func convertToUTC(date: Date) -> Date {
        PrintControl.shared.printTime("-TimePickView: Function: convertToUTC is firing")
        let sourceTimeZone = TimeZone.current
        let destinationTimeZone = TimeZone(identifier: "UTC")!

        let sourceOffset = sourceTimeZone.secondsFromGMT(for: date)
        let destinationOffset = destinationTimeZone.secondsFromGMT(for: date)
        let interval = TimeInterval(destinationOffset - sourceOffset)

        return date.addingTimeInterval(interval)
    }
    
    func updateFroopStartTime() {
        PrintControl.shared.printTime("-TimePickView: Function: updateFroopStartTime is firing")
        guard let hourInt = Int(hour), let minuteInt = Int(minute) else {
            return
        }
        
        var dateComponents = Calendar.current.dateComponents([.year, .month, .day], from: froopData.froopStartTime)
        dateComponents.hour = hourInt % 12 + (dayNight ? 12 : 0) // Convert to 24-hour format
        dateComponents.minute = minuteInt
        
        if let updatedDate = Calendar.current.date(from: dateComponents) {
            froopData.froopStartTime = updatedDate
        }
    }
    
    func updateFroopDuration() {
        PrintControl.shared.printTime("-TimePickView: Function: updateFroopDuration is firing")
        if let hourInt = Int(dHour), let minuteInt = Int(dMinute) {
            let totalSeconds = (hourInt * 60 + minuteInt) * 60
            froopData.froopDuration = totalSeconds
        }
    }
    
}

