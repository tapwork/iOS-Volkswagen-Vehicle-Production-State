//
//  URLTarget.swift
//  VWConnectAPI
//
//  Created by Christian Menschel on 11.04.21.
//

import Foundation

enum URLTarget {
    case login
    case token
    case state
    var url: URL {
        switch self {
        case .login:
            return URL(string: "https://www.volkswagen.de/de/besitzer-und-nutzer/myvolkswagen.html")!
        case .token:
            return URL(string: "https://www.volkswagen.de/app/authproxy/vw-de/tokens")!
        case .state:
            return URL(string: "https://w1hub-backend-production.apps.emea.vwapps.io/cars")!
        }
    }

    func request(accessToken: String) -> URLRequest {
        var request = URLRequest(url: url)
        let bearer = "Bearer \(accessToken)"
        request.setValue(bearer, forHTTPHeaderField: "authorization")
        return request
    }
}
