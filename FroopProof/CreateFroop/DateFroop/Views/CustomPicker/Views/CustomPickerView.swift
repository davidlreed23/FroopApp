//
//  CustomPickerView.swift
//  FroopProof
//
//  Created by David Reed on 1/30/23.
//

import SwiftUI
import Combine
import Foundation
import UIKit

struct CustomPickerView: View {
    
    
    
    @ObservedObject var printControl = PrintControl.shared
   
    @ObservedObject var froopDataListener = FroopDataListener.shared
   
 
    
    let hours = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12]
    let minutes = [0, 5, 10, 15, 20, 25, 30, 35, 40, 45, 50, 55]

    @State private var selectedHour = 0
    @State private var selectedMinute = 0
    @State private var selectedPeriod = 0
    @State private var lastDragAmount = CGSize.zero

    var body: some View {

        VStack (alignment: .leading) {



            VStack (alignment: .trailing) {
                HStack{
                    Text("START TIME")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(.gray)
                        .padding(.leading, 35)
                    Spacer()
                }

                HStack () {
                    Text("\(selectedHour)")
                        .font(.system(size: 110, weight: .thin))
                        .foregroundColor(.black)
                        .multilineTextAlignment(.center)
                        .frame(minWidth: 130, maxWidth: 130)
                        .border(.blue)
                        .onTapGesture {
                            self.selectedHour = (self.selectedHour + 11) % 12 + 1
                        }
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    self.selectedHour = max(0, min(12, self.selectedHour - Int(value.translation.height - self.lastDragAmount.height)))
                                    self.lastDragAmount = value.translation
                                }
                                .onEnded { _ in
                                    self.lastDragAmount = .zero
                                }
                        )
                        .defersSystemGestures(on: .vertical)
                        .defersSystemGestures(on: .horizontal)
                    Text(":")
                        .font(.system(size: 110, weight: .thin))
                        .foregroundColor(.black)
                        .multilineTextAlignment(.center)
                        .frame(minWidth: 10, maxWidth: 10)
                        .border(.blue)

                    Text("\(String(format: "%02d", minutes[selectedMinute]))")
                        .font(.system(size: 110, weight: .thin))
                        .foregroundColor(.black)

                        .frame(minWidth: 140, maxWidth: 140, alignment: .leading)
                        .border(.blue)

                    VStack{
                        Text(selectedPeriod == 0 ? "AM" : "PM")
                            .font(.system(size: 20, weight: .light))
                            .foregroundColor(.black)
                            .padding(.top, 40)
                            .frame(minWidth: 50, maxWidth: 50)
                            .border(.blue)
                            .multilineTextAlignment(.leading)
                            .offset(x: -20)
                        Spacer()
                    }
                    .padding(.top, 0)
                    .padding(.trailing, 10)
                }
                .padding(.trailing, 45)
                //MARK: Here is where the blue arrow code was....
                .defersSystemGestures(on: .vertical)
                .defersSystemGestures(on: .horizontal)

            }
            .defersSystemGestures(on: .vertical)
            .defersSystemGestures(on: .horizontal)

        }
        .frame(minWidth: 0,maxWidth: .infinity, minHeight: 250, maxHeight: 250)
        .background(Color.white)
        .cornerRadius(20)
        .shadow(radius: 10)
        .defersSystemGestures(on: .vertical)
        .defersSystemGestures(on: .horizontal)
    }
}

struct CustomPickerView_Previews: PreviewProvider {
    static var previews: some View {
        CustomPickerView()
    }
}
