//
//  macBitmoji Edition
//
//  Constants.swift
//  macBitmoji
//
//  Created by Mario Esposito on 4/9/20.
//

import Foundation

struct EndPoints {
    static let LoginURL     = "https://api.bitmoji.com/user/login"
    static let RefererURL   = "https://www.bitmoji.com/account_v2/"
    static let HostURL      = "api.bitmoji.com"
    static let OriginURL    = "https://www.bitmoji.com"
    static let AvatarURL    = "https://api.bitmoji.com/user/avatar"
    static let BitStripsURL = "https://render.bitstrips.com/v2/cpanel"
}

struct EndPointsParams {
    static let AppName      = "bitmoji"
    static let Platform     = "chrome"
    static let Token        = "bitmoji_bsauth_token"
}

struct AppKeys {
    static let AvatarUUID = "avatar_version_uuid"
    static let Token = "bitmoji-token"
}

enum ExecutionStatus {
    case failed
    case succeess
    case unknown
}

enum Messages {
    case DeviceIsOffline
    case DeviceIsNotResponding
}
