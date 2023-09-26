



import SwiftUI
import UIKit
import CoreLocation
import MapKit


class FroopDropPin: NSObject, MKAnnotation, Codable, ObservableObject {
    @Published var lastUpdated = Date()
    let id = UUID()
    dynamic var coordinate: CLLocationCoordinate2D
    var title: String?
    var subtitle: String?
    var messageBody: String?
    var color: UIColor?
    var creatorUID: String?   // New property
    var profileImageUrl: String?  // New property

    enum CodingKeys: String, CodingKey {
        case id, title, subtitle, messageBody, latitude, longitude, color, creatorUID, profileImageUrl
    }

    init(coordinate: CLLocationCoordinate2D, title: String?, subtitle: String?, messageBody: String?, color: UIColor?, creatorUID: String?, profileImageUrl: String?) {
        self.coordinate = coordinate
        self.title = title
        self.subtitle = subtitle
        self.messageBody = messageBody
        self.color = color
        self.creatorUID = creatorUID
        self.profileImageUrl = profileImageUrl
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let latitude = try container.decode(Double.self, forKey: .latitude)
        let longitude = try container.decode(Double.self, forKey: .longitude)
        coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        title = try container.decode(String?.self, forKey: .title)
        subtitle = try container.decode(String?.self, forKey: .subtitle)
        messageBody = try container.decode(String?.self, forKey: .messageBody)
        let colorString = try container.decode(String?.self, forKey: .color)
        color = colorString.flatMap { UIColor(hexString: $0) }
        creatorUID = try container.decode(String?.self, forKey: .creatorUID)
        profileImageUrl = try container.decode(String?.self, forKey: .profileImageUrl)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(coordinate.latitude, forKey: .latitude)
        try container.encode(coordinate.longitude, forKey: .longitude)
        try container.encode(title, forKey: .title)
        try container.encode(subtitle, forKey: .subtitle)
        try container.encode(messageBody, forKey: .messageBody)
        try container.encode(color?.toHexString(), forKey: .color)
        try container.encode(creatorUID, forKey: .creatorUID)
        try container.encode(profileImageUrl, forKey: .profileImageUrl)
    }

    var dictionary: [String: Any] {
        return [
            "coordinate": coordinate,
            "title": title ?? "",
            "subtitle": subtitle ?? "",
            "messageBody": messageBody ?? "",
            "color": color ?? UIColor(),
            "creatorUID": creatorUID ?? "",
            "profileImageUrl": profileImageUrl ?? ""
        ]
    }
}
