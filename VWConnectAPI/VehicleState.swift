//
//  VehicleState.swift
//  VWConnectAPI
//
//  Created by Christian Menschel on 11.04.21.
//

import Foundation

struct VehicleState: Codable, Equatable {
    let commissionNumber: String
    let vin: String?
    let deliveryDate: String
    let orderDate: Date
    let orderStatus: String
    let name: String
    let brand: String
    let modelCode: String
    let modelYear: String
    var checkpointNumber: String
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
