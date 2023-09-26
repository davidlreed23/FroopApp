//
//  NewFroopSummary.swift
//  FroopProof
//
//  Created by David Reed on 1/19/23.
//

import SwiftUI
import SwiftUIBlurView
import Kingfisher
import Firebase
import FirebaseAuth
import FirebaseFirestore


struct FroopSummaryView: View {
    @Environment(\.colorScheme) var colorScheme
    @ObservedObject var printControl = PrintControl.shared
    @ObservedObject var froopDataListener = FroopDataListener.shared
    var db = FirebaseServices.shared.db
    @ObservedObject var appStateManager = AppStateManager.shared
    @ObservedObject var timeZoneManager: TimeZoneManager = TimeZoneManager()
    @ObservedObject var myData = MyData.shared
    @ObservedObject var froopData: FroopData
    @ObservedObject var changeView: ChangeView
    @State var selectedFroopType: FroopType?
    @ObservedObject var froopTypeStore = FroopTypeStore()
    @Binding var showNFWalkthroughScreen: Bool
    @AppStorage("ProfileCompletionCurrentPage") var ProfileCompletionCurrentPage = 5
    @Binding var froopAdded: Bool
    var PCtotalPages = 6
    @State var myTimeZone: TimeZone = TimeZone.current
    @State private var formattedDateString: String = ""
    @State private var showMap = false
    
    var body: some View {
        ZStack{
            //MARK:  Background Layout Objects
            CFSBackGroundComponent(froopData: froopData)
                .onAppear {
                    appStateManager.froopIsEditing = true
                }
            Rectangle()
                .foregroundColor(.clear)
                .background(.ultraThinMaterial)
                .ignoresSafeArea()
            
            //MARK:  Backgrounds
            ZStack (alignment: .top) {
                
                //MARK: Full View Background
                VStack {
                    
                    Spacer()
                    
                    Rectangle()
                        .foregroundColor(.black)
                        .opacity(0.15)
                        .frame(height: UIScreen.main.bounds.height * 1.1)
                }
                .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
                .ignoresSafeArea()
                
                //MARK:  Top Screen Background Bar
                VStack {
                    Rectangle()
                        .fill(Color.black)
                        .opacity(0.5)
                        .frame(height: UIScreen.main.bounds.height * 0.15)
                    Spacer()
                    
                }
                .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
                .ignoresSafeArea()
                
            }
            .frame(minWidth: 0,maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
            
            //MARK: Content
            ZStack (alignment: .top){
                
                //MARK: Froop Content
                VStack (alignment: .center){
                    
                    //MARK:  Host Picture and Name
                    ZStack (alignment: .center){
                        VStack (alignment: .center) {
                            ZStack {
                                Circle()
                                    .frame(width: 128, height: 128, alignment: .center)
                                
                                KFImage(URL(string: MyData.shared.profileImageUrl))
                                    .placeholder {
                                        ProgressView()
                                    }
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 128, height: 128, alignment: .center)
                                    .clipShape(Circle())
                            }
                            .padding(.top, 35)
                            
                            HStack (alignment: .top){
                                Spacer()
                                Text("Host:")
                                    .font(.system(size: 18))
                                    .fontWeight(.medium)
                                    .foregroundColor(.white)
                                    .frame(alignment: .leading)
                                Text("\(MyData.shared.firstName) \(MyData.shared.lastName)")
                                    .font(.system(size: 18))
                                    .fontWeight(.light)
                                    .foregroundColor(.white)
                                    .frame(alignment: .leading)
                                Spacer()
                            }
                            .frame(width: 200)
                        }
                        .ignoresSafeArea(.keyboard)
                        .padding(.top, 25)
                        Spacer()
                    }
                    .padding(.bottom, 50)
                    
                    VStack {
                        //MARK: Title
                        ZStack {
                            ZStack {
                                RoundedRectangle(cornerRadius: 10)
                                    .foregroundColor(.white)
                                    .frame(height: 50)
                                    .padding(.leading, 15)
                                    .padding(.trailing, 15)
                                VStack {
                                    HStack {
                                        Text("Tap below to make changes")
                                            .font(.system(size: 14))
                                            .fontWeight(.regular)
                                            .foregroundColor(Color.white)
                                            .padding(.leading, 25)
                                            .padding(.top, -25)
                                        Spacer()
                                    }
                                    Spacer()
                                }
                                .frame(height: 50)
                                
                            }
                            VStack (alignment: .leading) {
                                Text("FROOP TITLE")
                                    .font(.system(size: 14))
                                    .fontWeight(.semibold)
                                    .foregroundColor(.black)
                                    .padding(.bottom, 5)
                                HStack (spacing: 0 ){
                                    Image(systemName: "t.circle")
                                        .frame(width: 60, height: 50)
                                        .scaledToFill()
                                        .font(.system(size: 24))
                                        .fontWeight(.medium)
                                        .foregroundColor(Color(red: 249/255, green: 0/255, blue: 98/255 ))
                                        .padding(.leading, 25)
                                        .frame(alignment: .center)
                                    Text("\"\(froopData.froopName)\"")
                                        .font(.system(size: 20))
                                        .fontWeight(.semibold)
                                        .foregroundColor(.black)
                                        .lineLimit(2)
                                        .padding(.trailing, 25)
                                    Spacer()
                                }
                                .frame(maxWidth: 400, maxHeight: 50)
                                
                            }
                        }
                        .frame(maxWidth: 400, maxHeight: 75)
                        .onTapGesture {
                            changeView.pageNumber = 4
                        }
                        
                        //MARK: Froop Date
                        Text("DATE")
                            .font(.system(size: 14))
                            .fontWeight(.semibold)
                            .foregroundColor(.black)
                            .padding(.bottom, 5)
                        
                        ZStack {
                            RoundedRectangle(cornerRadius: 10)
                                .foregroundColor(.white)
                                .frame(height: 50)
                                .padding(.leading, 15)
                                .padding(.trailing, 15)
                            
                            VStack (alignment: .leading) {
                                HStack (spacing: 0 ){
                                    Image(systemName: "clock")
                                        .frame(width: 60, height: 50)
                                        .scaledToFill()
                                        .font(.system(size: 24))
                                        .fontWeight(.medium)
                                        .foregroundColor(Color(red: 249/255, green: 0/255, blue: 98/255 ))
                                        .padding(.leading, 25)
                                        .frame(alignment: .center)
                                    Text(formattedDateString)
                                        .font(.system(size: 16))
                                        .fontWeight(.medium)
                                        .foregroundColor(.black)
                                        .lineLimit(2)
                                        .padding(.trailing, 25)
                                    Spacer()
                                }
                                .frame(maxWidth: 400, maxHeight: 50)
                                
                            }
                        }
                        .frame(maxWidth: 400, maxHeight: 75)
                        .onTapGesture {
                            changeView.pageNumber = 3
                        }
                        
                        //MARK: Froop Location
                        Text("ADDRESS")
                            .font(.system(size: 14))
                            .fontWeight(.semibold)
                            .foregroundColor(.black)
                            .padding(.bottom, 5)
                        
                        ZStack {
                            RoundedRectangle(cornerRadius: 10)
                                .foregroundColor(.white)
                                .frame(height: 75)
                                .padding(.leading, 15)
                                .padding(.trailing, 15)
                            VStack {
                                HStack (spacing: 0 ){
                                    Image(systemName: "mappin.and.ellipse")
                                        .frame(width: 60, height: 60)
                                        .scaledToFill()
                                        .font(.system(size: 24))
                                        .fontWeight(.medium)
                                        .foregroundColor(Color(red: 249/255, green: 0/255, blue: 98/255 ))
                                        .padding(.leading, 25)
                                        .frame(alignment: .center)
                                    VStack (alignment: .leading){
                                        Text(froopData.froopLocationtitle)
                                            .font(.system(size: 16))
                                            .fontWeight(.medium)
                                            .foregroundColor(.black)
                                            .padding(.trailing, 25)
                                        Text(froopData.froopLocationsubtitle)
                                            .font(.system(size: 14))
                                            .fontWeight(.light)
                                            .foregroundColor(.black)
                                            .lineLimit(2)
                                            .padding(.trailing, 25)
                                    }
                                    Spacer()
                                }
                                .frame(maxWidth: 400, maxHeight: 75)
                                .onTapGesture {
                                    changeView.pageNumber = 2
                                }
                                
                            }
                        }
                        .frame(maxWidth: 400, maxHeight: 75)
                        
                        //MARK: Froop Duration
                        Text("DURATION")
                            .font(.system(size: 14))
                            .fontWeight(.semibold)
                            .foregroundColor(.black)
                            .padding(.bottom, 5)
                        ZStack {
                            RoundedRectangle(cornerRadius: 10)
                                .foregroundColor(.white)
                                .frame(height: 50)
                                .padding(.leading, 15)
                                .padding(.trailing, 15)
                            VStack {
                                HStack (spacing: 0 ){
                                    Image(systemName: "hourglass.tophalf.filled")
                                        .frame(width: 60, height: 50)
                                        .scaledToFill()
                                        .font(.system(size: 24))
                                        .fontWeight(.medium)
                                        .foregroundColor(Color(red: 249/255, green: 0/255, blue: 98/255 ))
                                        .padding(.leading, 25)
                                        .frame(alignment: .center)
                                    Text("Duration: \(formatDuration(durationInSeconds: froopData.froopDuration))")
                                        .font(.system(size: 16))
                                        .fontWeight(.medium)
                                        .foregroundColor(.black)
                                        .lineLimit(2)
                                        .padding(.trailing, 25)
                                    
                                    Spacer()
                                }
                                .frame(maxWidth: 400, maxHeight: 50)
                            }
                        }
                        .frame(maxWidth: 400, maxHeight: 50)
                        .onTapGesture {
                            changeView.pageNumber = 3
                        }
                        
                        //MARK: Froop Type
                        Text("TYPE OF FROOP")
                            .font(.system(size: 14))
                            .fontWeight(.semibold)
                            .foregroundColor(.black)
                            .padding(.bottom, 5)
                        ZStack {
                            RoundedRectangle(cornerRadius: 10)
                                .foregroundColor(.white)
                                .frame(height: 50)
                                .padding(.leading, 15)
                                .padding(.trailing, 15)
                            VStack {
                                HStack (spacing: 0 ){
                                    if let froopType = FroopTypeStore.shared.froopTypes.first(where: { $0.id == froopData.froopType }) {
                                        Image(systemName: froopType.imageName)
                                            .frame(width: 60, height: 50)
                                            .scaledToFill()
                                            .font(.system(size: 24))
                                            .fontWeight(.medium)
                                            .foregroundColor(Color(red: 249/255, green: 0/255, blue: 98/255 ))
                                            .padding(.leading, 25)
                                            .frame(alignment: .center)
                                        Text("It's a \(froopType.name)")
                                            .font(.system(size: 16))
                                            .fontWeight(.medium)
                                            .foregroundColor(.black)
                                            .lineLimit(2)
                                            .padding(.trailing, 25)
                                    }
                                    Spacer()
                                }
                                .frame(maxWidth: 400, maxHeight: 50)
                            }
                        }
                        .frame(maxWidth: 400, maxHeight: 50)
                        .onTapGesture {
                            changeView.pageNumber = 1
                        }
                    }
                    
                    Spacer()
                    
                    //MARK: Save Froop Button
                    VStack {
                        HStack {
                            ZStack {
                                Rectangle()
                                    .foregroundColor(.clear)
                                    .frame(height: 75)
                                    .padding(.leading, 15)
                                    .padding(.trailing, 15)
                                Button {
                                    appStateManager.froopIsEditing = false
                                    if LocationManager.shared.locationUpdateTimerOn == true {
                                        TimerServices.shared.shouldCallupdateUserLocationInFirestore = true
                                    }
                                    if AppStateManager.shared.stateTransitionTimerOn == true {
                                        TimerServices.shared.shouldCallAppStateTransition = true
                                    }
                                    PrintControl.shared.printFroopCreation("Attempting to Save Froop")
                                    froopData.froopHostPic = MyData.shared.profileImageUrl
                                    froopData.froopHost = MyData.shared.froopUserID
                                    froopData.saveData()
                                    froopAdded = true
                                    
                                    if ProfileCompletionCurrentPage <= PCtotalPages {
                                        ProfileCompletionCurrentPage = 6
                                        print(ProfileCompletionCurrentPage)
                                    }
                                    showNFWalkthroughScreen = false
                                    
                                    // Schedule the location tracking notification
                                    let userNotificationsController = UserNotificationsController()
                                    userNotificationsController.scheduleLocationTrackingNotification(froopId: froopData.froopId, froopName: froopData.froopName, froopStartTime: froopData.froopStartTime)
                                    
                                    // Schedule the Froop reminder notification
                                    userNotificationsController.scheduleFroopReminderNotification(froopId: froopData.froopId, froopName: froopData.froopName, froopStartTime: froopData.froopStartTime)
                                    self.appStateManager.setupListener() { _ in }
                                } label: {
                                    Text("Save Froop")
                                        .font(.system(size: 28, weight: .thin))
                                        .foregroundColor(.white)
                                        .multilineTextAlignment(.center)
                                        .frame(width: 225, height: 45)
                                        .border(Color.white, width: 0.25)
                                        .padding(.top)
                                }
                            }
                        }
                    }
                    
                }
                .padding(.bottom, 20)
            }
            .onAppear {
                timeZoneManager.convertUTCToCurrent(date: froopData.froopStartTime, currentTZ: TimeZone.current.identifier) { convertedDate in
                    formattedDateString = timeZoneManager.formatDate(passedDate: convertedDate)
                }
                froopData.froopEndTime = froopData.froopStartTime.addingTimeInterval(TimeInterval(froopData.froopDuration))
                PrintControl.shared.printFroopCreation("Froop End Time:  \(froopData.froopEndTime)")
            }
        }
    }
    
    
    
    func formatDuration(durationInSeconds: Int) -> String {
        PrintControl.shared.printFroopCreation("-FroopSummaryView: Function: formatDuration is firing!")
        let hours = durationInSeconds / 3600
        let minutes = (durationInSeconds % 3600) / 60

        let hourString = hours == 1 ? "hour" : "hours"
        let minuteString = minutes == 1 ? "min" : "min"

        return String(format: "%02d \(hourString) %02d \(minuteString)", hours, minutes)
    }

    
    func uploadData(froopData: FroopData) {
        PrintControl.shared.printFroopCreation("-FroopSummaryView: Function: uploadData is firing!")
        
        let uid = FirebaseServices.shared.uid
        db.collection("users").document(uid).collection("myFroops").addDocument(data: froopData.dictionary) { (error) in
            if let error = error {
                PrintControl.shared.printFroopCreation("Error uploading data: \(error)")
            } else {
                PrintControl.shared.printFroopCreation("Data successfully uploaded")
            }
        }
    }
    
    
    func formatTime(creationTime: Date) -> String {
        PrintControl.shared.printFroopCreation("-FroopSummaryView: Function: formatTime is firing!")
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.minute, .hour, .day]
        formatter.unitsStyle = .abbreviated
        
        let currentTime = Date()
        let timeSinceCreation = currentTime.timeIntervalSince(creationTime)
        
        let formattedTime = formatter.string(from: timeSinceCreation) ?? ""
        
        return formattedTime
    }
}



