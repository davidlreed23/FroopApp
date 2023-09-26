//
//  TimeZoneManager.swift
//  FroopProof
//
//  Created by David Reed on 3/19/23.
//

import Foundation
import CoreLocation
import Foundation
import CoreLocation


class TimeZoneManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    @Published var userAccountTimeZone: TimeZone?
    @Published var userLocationTimeZone: TimeZone?
    @Published var froopTimeZone: TimeZone?
    @Published var locationTimeZone: TimeZone?
    
    
    override init() {
        super.init()
        self.locationManager.delegate = self
        self.locationManager.requestWhenInUseAuthorization()
        self.locationManager.startUpdatingLocation()
    }
    
    func formatTime(for date: Date, in timeZone: TimeZone) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        formatter.timeZone = timeZone
        return formatter.string(from: date)
    }
    
    func formatDate(for date: Date, in timeZoneIdentifier: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d, yyyy h:mm a"
        if let timeZone = TimeZone(identifier: timeZoneIdentifier) {
            formatter.timeZone = timeZone
        }
        return formatter.string(from: date)
    }
    
    func formatDuration(durationInSeconds: Int) -> String {
        let durationInMinutes = Int(ceil(Double(durationInSeconds) / 60))
        let roundedDurationInMinutes = Int(round(Double(durationInMinutes) / 15.0)) * 15
        let hours = roundedDurationInMinutes / 60
        let minutes = roundedDurationInMinutes % 60
        
        var durationString = ""
        
        if hours != 0 {
            durationString += "\(hours) hour"
            if hours != 1 {
                durationString += "s"
            }
        }
        
        if minutes != 0 {
            if durationString != "" {
                durationString += " "
            }
            durationString += "\(minutes) minute"
            if minutes != 1 {
                durationString += "s"
            }
        }
        
        return durationString
    }
    
    func formatDuration2(durationInMinutes: TimeInterval) -> String {
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .full
        formatter.allowedUnits = [.day, .hour, .minute]
        formatter.maximumUnitCount = 2
        return formatter.string(from: durationInMinutes) ?? ""
    }
    
    func formatDurationSinceCreation(creationDate: Date) -> String {
        let now = Date()
        let durationInMinutes = now.timeIntervalSince(creationDate)
        return formatDuration2(durationInMinutes: TimeInterval(Int(durationInMinutes)))
    }
    
    //MARK: Required Functions below
    
    func fetchTimeZone(latitude: Double, longitude: Double, completion: @escaping (TimeZone?) -> Void) {
        let location = CLLocation(latitude: latitude, longitude: longitude)
        
        CLGeocoder().reverseGeocodeLocation(location) { placemarks, error in
            guard let placemark = placemarks?.first, let timeZone = placemark.timeZone else {
                completion(nil)
                return
            }
            completion(timeZone)
        }
    }
    
    func fetchTimeZoneData() {
        let latitude = 37.7749
        let longitude = -122.4194
        
        fetchTimeZone(latitude: latitude, longitude: longitude) { timeZone in
            if let timeZone = timeZone {
                PrintControl.shared.printTimeZone("Fetched time zone: \(timeZone)")
                DispatchQueue.main.async {
                    self.locationTimeZone = timeZone
                }
            } else {
                PrintControl.shared.printTimeZone("Failed to fetch time zone")
            }
        }
    }
    
    func convertUTCToCurrent(date: Date, currentTZ: String, completion: @escaping (Date) -> Void) {
        PrintControl.shared.printTimeZone("One: date \(date)")
        PrintControl.shared.printTimeZone("Two: currentTZ \(currentTZ)")
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        formatter.timeZone = TimeZone(identifier: currentTZ) ?? TimeZone(identifier: "UTC")!
        
        let currentTimeString = formatter.string(from: date)
        
        PrintControl.shared.printTimeZone("Three: currentTimeString:  \(currentTimeString)")
        
        // Convert the string back to a Date object in the specified timezone
        if let convertedDate = formatter.date(from: currentTimeString) {
            PrintControl.shared.printTimeZone("Four: convertedDate: \(convertedDate)")
            completion(convertedDate)
        } else {
            completion(date) // Return the original date if conversion fails
            PrintControl.shared.printTimeZone("Five: completion(date) \(date)")
        }
    }
    
    func convertUTCToCurrentDetail(date: Date, currentTZ: String, completion: @escaping (Date) -> Void) {
        PrintControl.shared.printTimeZone("One: date \(date)")
        PrintControl.shared.printTimeZone("Two: currentTZ \(currentTZ)")
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        formatter.timeZone = TimeZone(identifier: currentTZ) ?? TimeZone(identifier: "UTC")!
        
        let currentTimeString = formatter.string(from: date)
        
        PrintControl.shared.printTimeZone("Three: currentTimeString:  \(currentTimeString)")
        
        // Convert the string back to a Date object in the specified timezone
        if let convertedDate = formatter.date(from: currentTimeString) {
            PrintControl.shared.printTimeZone("Four: convertedDate: \(convertedDate)")
            completion(convertedDate)
        } else {
            completion(date) // Return the original date if conversion fails
            PrintControl.shared.printTimeZone("Five: completion(date) \(date)")
        }
    }
    
    
    func convertDateToUTC(date: Date, oTZ: TimeZone) -> Date {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        formatter.timeZone = oTZ

        let dateString = formatter.string(from: date)
        formatter.timeZone = TimeZone(abbreviation: "UTC")

        guard let utcDate = formatter.date(from: dateString) else {
            fatalError("Failed to convert date to UTC")
        }

        return utcDate
    }
    
    func convertDateToTimeZone(dateString: String, timeZone: String, completion: @escaping (Date?, String, String) -> Void) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        dateFormatter.timeZone = TimeZone(abbreviation: "UTC")
        
        guard let dateInUTC = dateFormatter.date(from: dateString) else {
            PrintControl.shared.printTimeZone("Failed to parse date string")
            completion(nil, "", "")
            return
        }
        
        let destinationTimeZone = timeZone != "" ? TimeZone(identifier: timeZone) : TimeZone.current
        
        if let destinationTimeZone = destinationTimeZone {
            let sourceTimeZone = TimeZone(identifier: "UTC")!
            let interval = TimeInterval(destinationTimeZone.secondsFromGMT() - sourceTimeZone.secondsFromGMT())
            
            let destinationDate = dateInUTC.addingTimeInterval(interval)
            
            // Date string
            dateFormatter.dateFormat = "EEEE MMM. d"
            dateFormatter.timeZone = destinationTimeZone
            let dateString = dateFormatter.string(from: destinationDate)
            
            // Time string
            dateFormatter.dateFormat = "h:mm a"
            let timeString = dateFormatter.string(from: destinationDate)
            
            completion(destinationDate, dateString, timeString)
        } else {
            PrintControl.shared.printTimeZone("Invalid time zone identifier: \(String(describing: timeZone))")
            completion(nil, "", "")
        }
    }
    
    func formatDuration(_ durationInSeconds: TimeInterval) -> String {
        let weeks = Int(durationInSeconds) / (3600 * 24 * 7)
        let days = Int(durationInSeconds) / (3600 * 24) % 7
        let hours = Int(durationInSeconds) / 3600 % 24
        let minutes = Int(durationInSeconds) / 60 % 60
        
        var durationString = ""
        
        if weeks > 0 {
            durationString += "\(weeks)w "
        }
        if days > 0 {
            durationString += "\(days)d "
        }
        if hours > 0 {
            durationString += "\(hours)h "
        }
        if minutes > 0 {
            durationString += "\(minutes)m"
        }
        
        return durationString
    }
    
    func formatDateInCurrentTimeZone(dateString: String, format: String) -> String? {
        let currentTimeZone = TimeZone.current.identifier
        var formattedDateString: String?
        
        convertDateToTimeZone(dateString: dateString, timeZone: currentTimeZone) { _, timeString, timeZone in
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = format
            dateFormatter.timeZone = TimeZone(identifier: timeZone)
            formattedDateString = timeString
        }
        
        return formattedDateString
    }
    
    func formatDate(passedDate: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d',' h:mm a"
        let formattedDate = formatter.string(from: passedDate)
        return formattedDate
    }
    
    func formatDateDetail(passedDate: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d, h:mm a"
        let formattedDate = formatter.string(from: passedDate)
        return formattedDate
    }
    
}
