//
//  Union.swift
//  Copyright © 2023 The BLVD. All rights reserved.
//

import Foundation

protocol LexiconType: Codable {
    static var type: String { get }
}

enum UnionDecodingError: Error {
    case invalidType
}

enum UnionEncodingError: Error {
    case invalidValue
}

private enum UnionCodingKeys: String, CodingKey {
    case type = "$type"
}

extension Model {
    
    struct Union1<T1> where
        T1: LexiconType
    {
        @Indirect private var v1: T1?
        
        init(_ v: T1) { v1 = v }
        
        func value(_ type: T1.Type) -> T1? { v1 }
    }
    
    struct Union2<T1, T2> where
        T1: LexiconType,
        T2: LexiconType
    {
        @Indirect private var v1: T1?
        @Indirect private var v2: T2?
        
        init(_ v: T1) { v1 = v }
        init(_ v: T2) { v2 = v }
        
        func value(_ type: T1.Type) -> T1? { v1 }
        func value(_ type: T2.Type) -> T2? { v2 }
    }
    
    struct Union3<T1, T2, T3> where
        T1: LexiconType,
        T2: LexiconType,
        T3: LexiconType
    {
        @Indirect private var v1: T1?
        @Indirect private var v2: T2?
        @Indirect private var v3: T3?
        
        init(_ v: T1) { v1 = v }
        init(_ v: T2) { v2 = v }
        init(_ v: T3) { v3 = v }
        
        func value(_ type: T1.Type) -> T1? { v1 }
        func value(_ type: T2.Type) -> T2? { v2 }
        func value(_ type: T3.Type) -> T3? { v3 }
    }
    
    struct Union4<T1, T2, T3, T4> where
        T1: LexiconType,
        T2: LexiconType,
        T3: LexiconType,
        T4: LexiconType
    {
        @Indirect private var v1: T1?
        @Indirect private var v2: T2?
        @Indirect private var v3: T3?
        @Indirect private var v4: T4?
        
        init(_ v: T1) { v1 = v }
        init(_ v: T2) { v2 = v }
        init(_ v: T3) { v3 = v }
        init(_ v: T4) { v4 = v }
        
        func value(_ type: T1.Type) -> T1? { v1 }
        func value(_ type: T2.Type) -> T2? { v2 }
        func value(_ type: T3.Type) -> T3? { v3 }
        func value(_ type: T4.Type) -> T4? { v4 }
    }
    
}

// MARK: - Coding

extension Model.Union1: Codable {
    
    init(from decoder: Decoder) throws {
        let type = try decoder
            .container(keyedBy: UnionCodingKeys.self)
            .decode(String.self, forKey: .type)
        
        let c = try decoder.singleValueContainer()
        
        switch type {
        case T1.type: v1 = try c.decode(T1.self)
        default: throw UnionDecodingError.invalidType
        }
    }
    
    func encode(to encoder: Encoder) throws {
        let values: [Any?] = [v1]
        
        guard values.filter({ $0 != nil }).count == 1 else {
            throw UnionEncodingError.invalidValue
        }
        
        var container = encoder.container(keyedBy: UnionCodingKeys.self)
        
        if let v = v1 {
            try container.encode(T1.type, forKey: .type)
            try v.encode(to: encoder)
        }
    }
    
}

extension Model.Union2: Codable {
    
    init(from decoder: Decoder) throws {
        let type = try decoder
            .container(keyedBy: UnionCodingKeys.self)
            .decode(String.self, forKey: .type)
        
        let c = try decoder.singleValueContainer()
        
        switch type {
        case T1.type: v1 = try c.decode(T1.self)
        case T2.type: v2 = try c.decode(T2.self)
        default: throw UnionDecodingError.invalidType
        }
    }
    
    func encode(to encoder: Encoder) throws {
        let values: [Any?] = [v1, v2]
        
        guard values.filter({ $0 != nil }).count == 1 else {
            throw UnionEncodingError.invalidValue
        }
        
        var container = encoder.container(keyedBy: UnionCodingKeys.self)
        
        if let v = v1 {
            try container.encode(T1.type, forKey: .type)
            try v.encode(to: encoder)
        }
        if let v = v2 {
            try container.encode(T2.type, forKey: .type)
            try v.encode(to: encoder)
        }
    }
    
}

extension Model.Union3: Codable {
    
    init(from decoder: Decoder) throws {
        let type = try decoder
            .container(keyedBy: UnionCodingKeys.self)
            .decode(String.self, forKey: .type)
        
        let c = try decoder.singleValueContainer()
        
        switch type {
        case T1.type: v1 = try c.decode(T1.self)
        case T2.type: v2 = try c.decode(T2.self)
        case T3.type: v3 = try c.decode(T3.self)
        default: throw UnionDecodingError.invalidType
        }
    }
    
    func encode(to encoder: Encoder) throws {
        let values: [Any?] = [v1, v2, v3]
        
        guard values.filter({ $0 != nil }).count == 1 else {
            throw UnionEncodingError.invalidValue
        }
        
        var container = encoder.container(keyedBy: UnionCodingKeys.self)
        
        if let v = v1 {
            try container.encode(T1.type, forKey: .type)
            try v.encode(to: encoder)
        }
        if let v = v2 {
            try container.encode(T2.type, forKey: .type)
            try v.encode(to: encoder)
        }
        if let v = v3 {
            try container.encode(T3.type, forKey: .type)
            try v.encode(to: encoder)
        }
    }
    
}

extension Model.Union4: Codable {
    
    init(from decoder: Decoder) throws {
        let type = try decoder
            .container(keyedBy: UnionCodingKeys.self)
            .decode(String.self, forKey: .type)
        
        let c = try decoder.singleValueContainer()
        
        switch type {
        case T1.type: v1 = try c.decode(T1.self)
        case T2.type: v2 = try c.decode(T2.self)
        case T3.type: v3 = try c.decode(T3.self)
        case T4.type: v4 = try c.decode(T4.self)
        default: throw UnionDecodingError.invalidType
        }
    }
    
    func encode(to encoder: Encoder) throws {
        let values: [Any?] = [v1, v2, v3, v4]
        
        guard values.filter({ $0 != nil }).count == 1 else {
            throw UnionEncodingError.invalidValue
        }
        
        var container = encoder.container(keyedBy: UnionCodingKeys.self)
        
        if let v = v1 {
            try container.encode(T1.type, forKey: .type)
            try v.encode(to: encoder)
        }
        if let v = v2 {
            try container.encode(T2.type, forKey: .type)
            try v.encode(to: encoder)
        }
        if let v = v3 {
            try container.encode(T3.type, forKey: .type)
            try v.encode(to: encoder)
        }
        if let v = v4 {
            try container.encode(T4.type, forKey: .type)
            try v.encode(to: encoder)
        }
    }
    
}
