//
//  FroopTypeList.swift
//  FroopProof
//
//  Created by David Reed on 1/19/23.
//

import SwiftUI
import Firebase
import FirebaseAuth
import FirebaseFirestore
import FirebaseFirestoreSwift
import UIKit




struct FroopTypes: Codable {
    var id: String
    var name: String
    var imageName: String
    var category: [String]
    
    func toDictionary() -> [String: Any] {
        PrintControl.shared.printFroopCreation("-FroopTypes: Function: toDictionary firing")
        return ["id": id,"name": name,"imageName": imageName,"category": category]
    }
}

struct FroopTypeListOne: Codable {
    static let shared = FroopTypeListOne()
    var data = [String: Any]()
    var id: String = ""
    var name: String = ""
    var imageName: String = ""
    var category: [String] = []
    
    
    
    var dictionary: [String: Any] {
        return [
            "id": id,
            "name": name,
            "imageName": imageName,
            "category": category
        ]
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case imageName
        case category
    }
    
    var froopTypes: [FroopTypes] = [
        FroopTypes(id: "1", name: "Simple Gathering", imageName: "person.3.fill", category: ["General", "hang", "get", "together"]),
        FroopTypes(id: "2", name: "Birthday", imageName: "birthday.cake.fill", category: ["Food","Party", "Celebration", "Cake"]),
        FroopTypes(id: "3", name: "Dinner Party", imageName: "fork.knife.circle.fill", category: ["Food"]),
        FroopTypes(id: "4", name: "Golf Outing", imageName: "figure.golf", category: ["Sport"]),
        FroopTypes(id: "5", name: "Camping Trip", imageName: "tent.fill", category: ["Camping"]),
        FroopTypes(id: "6", name: "Hiking Excursion", imageName: "figure.hiking", category: ["Sport"]),
        FroopTypes(id: "7", name: "Ski Trip", imageName: "figure.snowboarding", category: ["Sport"]),
        FroopTypes(id: "8", name: "Beach Day", imageName: "beach.umbrella.fill", category: ["Beach"]),
        FroopTypes(id: "9", name: "Wine Tasting", imageName: "wineglass.fill", category: ["Food"]),
        FroopTypes(id: "10", name: "Brewery Tour", imageName: "mug.fill", category: ["Food"]),
        FroopTypes(id: "11", name: "Cooking Class", imageName: "cooktop.fill", category: ["Food"]),
        FroopTypes(id: "12", name: "Concert", imageName: "music.note.house.fill", category: ["Show"]),
        FroopTypes(id: "13", name: "Comedy Show", imageName: "music.mic", category: ["Show"]),
        FroopTypes(id: "14", name: "Theater Performance", imageName: "ticket.fill", category: ["Show"]),
        FroopTypes(id: "15", name: "Museum Visit", imageName: "photo.artframe", category: ["Destination"]),
        FroopTypes(id: "16", name: "Zoo Visit", imageName: "pawprint.fill", category: ["Destination"]),
        FroopTypes(id: "17", name: "Aquarium Visit", imageName: "fish.fill", category: ["Destination"]),
        FroopTypes(id: "18", name: "Amusement Park Visit", imageName: "flag.2.crossed.fill", category: ["Destination"]),
        FroopTypes(id: "19", name: "Water Park Visit", imageName: "figure.open.water.swim", category: ["Destination"]),
        FroopTypes(id: "20", name: "Picnic", imageName: "takeoutbag.and.cup.and.straw.fill", category: ["Food"]),
        FroopTypes(id: "21", name: "Barbecue", imageName: "flame.fill", category: ["Food"]),
        FroopTypes(id: "22", name: "Pool Party", imageName: "figure.pool.swim", category: ["Hang"]),
        FroopTypes(id: "23", name: "Game Night", imageName: "gamecontroller.fill", category: ["Hang"]),
        FroopTypes(id: "24", name: "Movie Night", imageName: "film.fill", category: ["Hang"]),
        FroopTypes(id: "25", name: "Karaoke Night", imageName: "music.mic.circle.fill", category: ["Hang"]),
        FroopTypes(id: "26", name: "Bowling Night", imageName: "figure.bowling", category: ["]Sport"]),
        FroopTypes(id: "27", name: "Airport Pickup", imageName: "airplane.arrival", category: ["Flying"])
    ]
    
}
