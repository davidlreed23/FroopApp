//
//  DatePickView.swift
//  FroopProof
//
//  Created by David Reed on 1/25/23.
//

import SwiftUI
import UIKit
import Foundation



struct DatePickView: View {
    @Environment(\.colorScheme) var colorScheme
    
    
    @ObservedObject var printControl = PrintControl.shared
   
    @ObservedObject var froopDataListener = FroopDataListener.shared
   
 
    
    @Binding var transClock: Bool
    @Binding var datePicked: Bool
    @ObservedObject var froopData: FroopData
//    @State var selectedDate = Date()
    @State private var isTouched = false
  
    

    
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
        ZStack {
           
                        
            VStack {
                ZStack(alignment: .top) {
                    Rectangle()
                        .fill(Color.black)
                        .opacity(0.8)
                        .frame(width: 450, height: transClock ? 50 : 385, alignment: .topLeading)
                        .transition(.move(edge: .bottom))
                        .offset(y: transClock ? -35 : 0)
                    
                    VStack {
                        Text(datePicked ? selectedDateString : "When is it happening?")
                            .font(.system(size: 48, weight: .thin))
                            .foregroundColor(.white)
                            .frame(maxWidth: 400)
                            .multilineTextAlignment(.center)
                            .padding(.top, 150)
                            
                     
                        
                        if datePicked {
                            Text("Confirm Date?")
                                .font(.system(size: 28, weight: .thin))
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                                .frame(width: 225, height: 45)
                                .border(Color.gray, width: 1)
                                .padding(.top)
                                .onTapGesture {
                                    withAnimation(.spring()) {
                                        transClock = true
                                       
                                       
                                        
                                        
                                        PrintControl.shared.printTime("XXOOXXOOXXOOXXOO \(froopData.id)")
                                        PrintControl.shared.printTime("Minute: \(froopData.froopStartTime.formatted(.dateTime.minute()))")
                                        PrintControl.shared.printTime("Hour: \(froopData.froopStartTime.formatted(.dateTime.hour()))")
                                        PrintControl.shared.printTime("Date: \(froopData.froopStartTime.formatted(.dateTime.day().month().year()))")
                                        PrintControl.shared.printTime("Month: \(froopData.froopStartTime.formatted(.dateTime.month()))")
                                        PrintControl.shared.printTime("Day: \(froopData.froopStartTime.formatted(.dateTime.day()))")
                                        PrintControl.shared.printTime("Year: \(froopData.froopStartTime.formatted(.dateTime.year()))")
                                        PrintControl.shared.printTime("TimeZone: \(froopData.froopStartTime.formatted(.dateTime.day().month().year()))")
                                    }
                                }
                        }
                        
                    }
                    .opacity(transClock ? 0 : 1)
                    .animation(Animation.easeInOut(duration: 0.4), value: datePicked)
                }
                .frame(minWidth: 0,maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
                
                .ignoresSafeArea()
                
                //MARK:  Custom Bar Navigation for DatePicker
                ZStack(alignment: .center){
                    Rectangle()
                        .fill(Color.black)
                        .opacity(1)
                        .frame(height: 75)
                    HStack {
                        ZStack(alignment: .center){
                            Rectangle()
                                .fill(Color.black)
                                .opacity(0.001)
                                .frame(width: 75, height: 75)
                            Image(systemName: "chevron.left")
                                .foregroundColor(.white)
                                .opacity(transClock ? 0 : 1)
                                .padding(.leading, 25)
                        }
                        .onTapGesture {
                            self.moveToPreviousMonth()
                        }
                        
                        Spacer()
                        ZStack{
                            
                            Text(dateString)
                                .font(.title2)
                                .fontWeight(.light)
                                .opacity(transClock ? 0 : 1)
                                .foregroundColor(.white)
                                .font(.system(size: 16, weight: .semibold))
                                .multilineTextAlignment(.center)
                            VStack{
                                Text(selectedDateString)
                                    .font(.title2)
                                    .fontWeight(.light)
                                    .opacity(transClock ? 1 : 0)
                                    .foregroundColor(.white)
                                    .font(.system(size: 16, weight: .semibold))
                                    .multilineTextAlignment(.center)
                                Image(systemName: "chevron.down")
                                    .padding(.top, 1)
                                    .foregroundColor(.gray)
                                    .opacity(transClock ? 1 : 0)
                            }
                            .padding(.top, 20)
                            Rectangle()
                                .fill(Color.black)
                                .opacity(0.001)
                                .frame(width: 200, height: 75)
                                .onTapGesture {
                                    withAnimation(.spring()) {
                                        transClock = false
                                    }
                                }
                            
                        }
                        
                        Spacer()
                        ZStack(alignment: .center){
                            Rectangle()
                                .fill(Color.black)
                                .opacity(0.001)
                                .frame(width: 75, height: 75)
                            Image(systemName: "chevron.right")
                                .foregroundColor(.white)
                                .opacity(transClock ? 0 : 1)
                                .padding(.trailing, 25)
                            
                        }
                        
                        .onTapGesture {
                            self.moveToNextMonth()
                        }
                        .frame(height: 75)
                    }
                    
                    
                }
                .frame(minWidth: 0,maxWidth: .infinity, minHeight: 0, maxHeight: 75)
                
                .offset(y: transClock ? -325: 0)
                
                ZStack (alignment: .top) {
                    
                    DatePicker(
                        "Froop Date",
                        selection: Binding(
                            get: { froopData.froopStartTime },
                            set: { newValue in
                                let calendar = Calendar.current
                                let dateComponents = calendar.dateComponents([.year, .month, .day], from: newValue)
                                let newDate = calendar.date(from: dateComponents)!
                                froopData.froopStartTime = newDate
                            }
                        ),
                        in: Date()...,
                        displayedComponents: .date)
                    .environment(\.timeZone, TimeZone.current)
                    .datePickerStyle(GraphicalDatePickerStyle())

                }
                .opacity(transClock ? 0 : 1)
            }
            
            .frame(minWidth: 0,maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
            TouchCaptureView {
                if !isTouched {
                    isTouched = true
                    datePicked = true
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.clear)
            .opacity(isTouched ? 0.0 : 1.0)
        }
        .frame(minWidth: 0,maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
        .ignoresSafeArea()
    }
    func nextMonth() {
        PrintControl.shared.printTime("-DatePickView: Function: nextMonth is firing")
        self.froopData.froopStartTime = Calendar.current.date(byAdding: .month, value: 1, to: self.froopData.froopStartTime) ?? Date()
    }
    
    func moveToNextMonth() {
        PrintControl.shared.printTime("-DatePickView: Function: moveToNextMonth is firing")
        let nextMonth = Calendar.current.date(byAdding: .month, value: 1, to: froopData.froopStartTime)
        froopData.froopStartTime = nextMonth ?? froopData.froopStartTime
    }
    
    func moveToPreviousMonth() {
        PrintControl.shared.printTime("-DatePickView: Function: moveToPreviousMonth is firing")
        if Calendar.current.component(.month, from: froopData.froopStartTime) == Calendar.current.component(.month, from: Date()) {
            //Don't update the month
        } else {
            let previousMonth = Calendar.current.date(byAdding: .month, value: -1, to: froopData.froopStartTime)
            froopData.froopStartTime = previousMonth ?? froopData.froopStartTime
        }
    }
    func currentDateComponentsInTimeZone(timeZoneIdentifier: String) -> DateComponents {
        PrintControl.shared.printTime("-DatePickView: Function: currentDateComponentsInTimeZone is firing")
        let now = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = TimeZone(identifier: timeZoneIdentifier)
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        
        let dateString = dateFormatter.string(from: now)
        let dateInTimeZone = dateFormatter.date(from: dateString) ?? now
        
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: dateInTimeZone)
        
        return components
    }
    
    func convertToLocalTime(date: Date) -> Date {
        PrintControl.shared.printTime("-DatePickView: Function: convertToLocalTime is firing")
        let sourceTimeZone = TimeZone(identifier: "UTC")!
        let destinationTimeZone = TimeZone.current
        
        let sourceOffset = sourceTimeZone.secondsFromGMT(for: date)
        let destinationOffset = destinationTimeZone.secondsFromGMT(for: date)
        let interval = TimeInterval(destinationOffset - sourceOffset)
        
        return date.addingTimeInterval(interval)
    }
    
}

