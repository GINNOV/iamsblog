//
//  imoji.swift
//  macBitmoji
//
//  Created by Mario Esposito on 4/27/20.
//  Copyright © 2020 IENA WHITE. All rights reserved.
//

import Foundation

// This file was generated from JSON Schema using quicktype, do not modify it directly.
// To parse the JSON, add this file to your project and do:
//
//

// MARK: - Groups
struct Bits: Codable {
    var imoji, friends: [Friend]
    var packs: [JSONAny]
    var outfits: Outfits
    var announcers: Announcers
    var experiments: Experiments
    var tagTiles: [TagTile]
    var searchTerms: [SearchTerm]
    var etag: String

    enum CodingKeys: String, CodingKey {
        case imoji, friends, packs, outfits, announcers, experiments
        case tagTiles = "tag_tiles"
        case searchTerms = "search_terms"
        case etag
    }
}

// MARK: - Announcers
struct Announcers: Codable {
    var fashionAnnouncer: FashionAnnouncer

    enum CodingKeys: String, CodingKey {
        case fashionAnnouncer = "fashion_announcer"
    }
}

// MARK: - FashionAnnouncer
struct FashionAnnouncer: Codable {
    var id: Int
    var enabled: Bool
    var link: String
}

// MARK: - Experiments
struct Experiments: Codable {
    var defaultTab: String
    var settingsButtonContainer: Int

    enum CodingKeys: String, CodingKey {
        case defaultTab = "default_tab"
        case settingsButtonContainer = "settings_button_container"
    }
}

// MARK: - Friend
struct Friend: Codable {
    var templateID, comicID: String
    var src: String
    var supertags: [Supertag]
    var tags, categories: [String]
    var altText, descriptiveAltText: String?

    enum CodingKeys: String, CodingKey {
        case templateID = "template_id"
        case comicID = "comic_id"
        case src, supertags, tags, categories
        case altText = "alt_text"
        case descriptiveAltText = "descriptive_alt_text"
    }
}

enum Supertag: String, Codable {
    case ifrowny = "#ifrowny"
    case ilove = "#ilove"
    case inuanced = "#inuanced"
    case ismiley = "#ismiley"
    case iwacky = "#iwacky"
    case popmoji = "#popmoji"
    case search = "#search"
}

// MARK: - Outfits
struct Outfits: Codable {
    var version: Int
    var male, female: Male
}

// MARK: - Male
struct Male: Codable {
    var fittingRoomTemplateID: String
    var brands: [Brand]
    var showcase: [Showcase]

    enum CodingKeys: String, CodingKey {
        case fittingRoomTemplateID = "fitting_room_template_id"
        case brands, showcase
    }
}

// MARK: - Brand
struct Brand: Codable {
    var id: Int
    var name: String
    var logo: String
    var headerBackground, storeBackground: String
    var bgColor, fgColor: String
    var theme: Theme
    var visibleInSnapchat: Bool
    var outfits: [Outfit]

    enum CodingKeys: String, CodingKey {
        case id, name, logo
        case headerBackground = "header_background"
        case storeBackground = "store_background"
        case bgColor = "bg_color"
        case fgColor = "fg_color"
        case theme
        case visibleInSnapchat = "visible_in_snapchat"
        case outfits
    }
}

// MARK: - Outfit
struct Outfit: Codable {
    var id: Int
    var outfit: String
    var hasCustomHead: Bool
    var sublogo, outfitDescription: String
    var image: String

    enum CodingKeys: String, CodingKey {
        case id, outfit
        case hasCustomHead = "has_custom_head"
        case sublogo
        case outfitDescription = "description"
        case image
    }
}

enum Theme: String, Codable {
    case dark = "dark"
    case light = "light"
}

// MARK: - Showcase
struct Showcase: Codable {
    var image: String
}

// MARK: - SearchTerm
struct SearchTerm: Codable {
    var term: String
}

// MARK: - TagTile
struct TagTile: Codable {
    var name, color: String
}

// MARK: - Encode/decode helpers

class JSONNull: Codable, Hashable {

    public static func == (lhs: JSONNull, rhs: JSONNull) -> Bool {
        return true
    }

    public var hashValue: Int {
        return 0
    }

    public func hash(into hasher: inout Hasher) {
        // No-op
    }

    public init() {}

    public required init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if !container.decodeNil() {
            throw DecodingError.typeMismatch(JSONNull.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Wrong type for JSONNull"))
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encodeNil()
    }
}

class JSONCodingKey: CodingKey {
    let key: String

    required init?(intValue: Int) {
        return nil
    }

    required init?(stringValue: String) {
        key = stringValue
    }

    var intValue: Int? {
        return nil
    }

    var stringValue: String {
        return key
    }
}

class JSONAny: Codable {

    let value: Any

    static func decodingError(forCodingPath codingPath: [CodingKey]) -> DecodingError {
        let context = DecodingError.Context(codingPath: codingPath, debugDescription: "Cannot decode JSONAny")
        return DecodingError.typeMismatch(JSONAny.self, context)
    }

    static func encodingError(forValue value: Any, codingPath: [CodingKey]) -> EncodingError {
        let context = EncodingError.Context(codingPath: codingPath, debugDescription: "Cannot encode JSONAny")
        return EncodingError.invalidValue(value, context)
    }

    static func decode(from container: SingleValueDecodingContainer) throws -> Any {
        if let value = try? container.decode(Bool.self) {
            return value
        }
        if let value = try? container.decode(Int64.self) {
            return value
        }
        if let value = try? container.decode(Double.self) {
            return value
        }
        if let value = try? container.decode(String.self) {
            return value
        }
        if container.decodeNil() {
            return JSONNull()
        }
        throw decodingError(forCodingPath: container.codingPath)
    }

    static func decode(from container: inout UnkeyedDecodingContainer) throws -> Any {
        if let value = try? container.decode(Bool.self) {
            return value
        }
        if let value = try? container.decode(Int64.self) {
            return value
        }
        if let value = try? container.decode(Double.self) {
            return value
        }
        if let value = try? container.decode(String.self) {
            return value
        }
        if let value = try? container.decodeNil() {
            if value {
                return JSONNull()
            }
        }
        if var container = try? container.nestedUnkeyedContainer() {
            return try decodeArray(from: &container)
        }
        if var container = try? container.nestedContainer(keyedBy: JSONCodingKey.self) {
            return try decodeDictionary(from: &container)
        }
        throw decodingError(forCodingPath: container.codingPath)
    }

    static func decode(from container: inout KeyedDecodingContainer<JSONCodingKey>, forKey key: JSONCodingKey) throws -> Any {
        if let value = try? container.decode(Bool.self, forKey: key) {
            return value
        }
        if let value = try? container.decode(Int64.self, forKey: key) {
            return value
        }
        if let value = try? container.decode(Double.self, forKey: key) {
            return value
        }
        if let value = try? container.decode(String.self, forKey: key) {
            return value
        }
        if let value = try? container.decodeNil(forKey: key) {
            if value {
                return JSONNull()
            }
        }
        if var container = try? container.nestedUnkeyedContainer(forKey: key) {
            return try decodeArray(from: &container)
        }
        if var container = try? container.nestedContainer(keyedBy: JSONCodingKey.self, forKey: key) {
            return try decodeDictionary(from: &container)
        }
        throw decodingError(forCodingPath: container.codingPath)
    }

    static func decodeArray(from container: inout UnkeyedDecodingContainer) throws -> [Any] {
        var arr: [Any] = []
        while !container.isAtEnd {
            let value = try decode(from: &container)
            arr.append(value)
        }
        return arr
    }

    static func decodeDictionary(from container: inout KeyedDecodingContainer<JSONCodingKey>) throws -> [String: Any] {
        var dict = [String: Any]()
        for key in container.allKeys {
            let value = try decode(from: &container, forKey: key)
            dict[key.stringValue] = value
        }
        return dict
    }

    static func encode(to container: inout UnkeyedEncodingContainer, array: [Any]) throws {
        for value in array {
            if let value = value as? Bool {
                try container.encode(value)
            } else if let value = value as? Int64 {
                try container.encode(value)
            } else if let value = value as? Double {
                try container.encode(value)
            } else if let value = value as? String {
                try container.encode(value)
            } else if value is JSONNull {
                try container.encodeNil()
            } else if let value = value as? [Any] {
                var container = container.nestedUnkeyedContainer()
                try encode(to: &container, array: value)
            } else if let value = value as? [String: Any] {
                var container = container.nestedContainer(keyedBy: JSONCodingKey.self)
                try encode(to: &container, dictionary: value)
            } else {
                throw encodingError(forValue: value, codingPath: container.codingPath)
            }
        }
    }

    static func encode(to container: inout KeyedEncodingContainer<JSONCodingKey>, dictionary: [String: Any]) throws {
        for (key, value) in dictionary {
            let key = JSONCodingKey(stringValue: key)!
            if let value = value as? Bool {
                try container.encode(value, forKey: key)
            } else if let value = value as? Int64 {
                try container.encode(value, forKey: key)
            } else if let value = value as? Double {
                try container.encode(value, forKey: key)
            } else if let value = value as? String {
                try container.encode(value, forKey: key)
            } else if value is JSONNull {
                try container.encodeNil(forKey: key)
            } else if let value = value as? [Any] {
                var container = container.nestedUnkeyedContainer(forKey: key)
                try encode(to: &container, array: value)
            } else if let value = value as? [String: Any] {
                var container = container.nestedContainer(keyedBy: JSONCodingKey.self, forKey: key)
                try encode(to: &container, dictionary: value)
            } else {
                throw encodingError(forValue: value, codingPath: container.codingPath)
            }
        }
    }

    static func encode(to container: inout SingleValueEncodingContainer, value: Any) throws {
        if let value = value as? Bool {
            try container.encode(value)
        } else if let value = value as? Int64 {
            try container.encode(value)
        } else if let value = value as? Double {
            try container.encode(value)
        } else if let value = value as? String {
            try container.encode(value)
        } else if value is JSONNull {
            try container.encodeNil()
        } else {
            throw encodingError(forValue: value, codingPath: container.codingPath)
        }
    }

    public required init(from decoder: Decoder) throws {
        if var arrayContainer = try? decoder.unkeyedContainer() {
            self.value = try JSONAny.decodeArray(from: &arrayContainer)
        } else if var container = try? decoder.container(keyedBy: JSONCodingKey.self) {
            self.value = try JSONAny.decodeDictionary(from: &container)
        } else {
            let container = try decoder.singleValueContainer()
            self.value = try JSONAny.decode(from: container)
        }
    }

    public func encode(to encoder: Encoder) throws {
        if let arr = self.value as? [Any] {
            var container = encoder.unkeyedContainer()
            try JSONAny.encode(to: &container, array: arr)
        } else if let dict = self.value as? [String: Any] {
            var container = encoder.container(keyedBy: JSONCodingKey.self)
            try JSONAny.encode(to: &container, dictionary: dict)
        } else {
            var container = encoder.singleValueContainer()
            try JSONAny.encode(to: &container, value: self.value)
        }
    }
}
