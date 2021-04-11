//
//  VehicleState.swift
//  VWConnectAPI
//
//  Created by Christian Menschel on 11.04.21.
//

import Foundation

struct VehicleState: Codable {
    let commissionNumber: String
    let vin: String?
    let deliveryDate: String
    let orderDate: Date
    let orderStatus: String
    let name: String
    let brand: String
    let modelCode: String
    let modelYear: String
    let checkpointNumber: String
    let detailStatus: String

    var orderDateLocalized: String {
        DateFormatter.medium.string(from: orderDate)
    }
    var deliveryDateLocalized: String {
        guard let date = DateFormatter.delivery.date(from: deliveryDate) else {
            return deliveryDate
        }
        return DateFormatter.medium.string(from: date)
    }
}

extension DateFormatter {
    static var zulu: DateFormatter {
        let dateformatter = DateFormatter()
        dateformatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        return dateformatter
    }

    static var delivery: DateFormatter {
        let dateformatter = DateFormatter()
        dateformatter.dateFormat = "yyyy-MM-dd"
        return dateformatter
    }

    static var medium: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }
}

extension JSONDecoder {
    static var shared: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .formatted(DateFormatter.zulu)
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }()
}
