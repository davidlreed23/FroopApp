import Combine
import SwiftUI
import MapKit
import FirebaseFirestore
import FirebaseFirestoreSwift
import FirebaseAuth

class FroopType: ObservableObject, Codable, Hashable, Equatable {
    @ObservedObject var printControl = PrintControl.shared
    @ObservedObject var froopDataListener = FroopDataListener.shared
    @Published var id: Int = 0
    @Published var name: String = ""
    @Published var imageName: String = ""
    @Published var category: [String] = []
    var db = FirebaseServices.shared.db

    
    static func == (lhs: FroopType, rhs: FroopType) -> Bool {
        return lhs.id == rhs.id && lhs.name == rhs.name && lhs.imageName == rhs.imageName && lhs.category == rhs.category
    }
    
    func hash(into hasher: inout Hasher) {
        PrintControl.shared.printFroopCreation("-FroopType: Function: hash firing")
        hasher.combine(id)
        hasher.combine(name)
        hasher.combine(imageName)
        hasher.combine(category)
    }
    
    var dictionary: [String: Any] {
        return [
        "name": name,
        "imageName": imageName,
        "category:": category
        ]
    }
    
    func encode(to encoder: Encoder) throws {
        PrintControl.shared.printFroopCreation("-FroopType: Function: encode firing")
           var container = encoder.container(keyedBy: CodingKeys.self)
           try container.encode(id, forKey: .id)
           try container.encode(name, forKey: .name)
           try container.encode(imageName, forKey: .imageName)
           try container.encode(category, forKey: .category)
        PrintControl.shared.printFroopCreation("retrieving FroopTypeData Data")
       }
    
    enum CodingKeys: String, CodingKey {
        case id, name, imageName, category
    }
    
    init(dictionary: [String: Any]) {
        self.id = dictionary["id"] as? Int ?? 0
        self.name = dictionary["name"] as? String ?? ""
        self.imageName = dictionary["imageName"] as? String ?? ""
        self.category = dictionary["category"] as? [String] ?? []
    }

    required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        id = try values.decode(Int.self, forKey: .id)
        name = try values.decode(String.self, forKey: .name)
        imageName = try values.decode(String.self, forKey: .imageName)
        category = try values.decode([String].self, forKey: .category)
    }

}
