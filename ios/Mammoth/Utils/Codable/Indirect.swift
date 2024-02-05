//
//  Indirect.swift
//  Copyright © 2023 The BLVD. All rights reserved.
//

import Foundation

@propertyWrapper
enum Indirect<T> {
    indirect case wrapped(T)
    
    init(wrappedValue initialValue: T) {
        self = .wrapped(initialValue)
    }
    
    var wrappedValue: T {
        get { switch self { case .wrapped(let x): return x } }
        set { self = .wrapped(newValue) }
    }
}

extension Indirect: Decodable where T: Decodable {
    init(from decoder: Decoder) throws {
        try self.init(wrappedValue: T(from: decoder))
    }
}

extension Indirect: Encodable where T: Encodable {
    func encode(to encoder: Encoder) throws {
        try wrappedValue.encode(to: encoder)
    }
}

extension KeyedDecodingContainer {
    func decode<T: Decodable>(
        _: Indirect<T>.Type,
        forKey key: Key
    ) throws -> Indirect<T> {
        let value = try decode(T.self, forKey: key)
        return Indirect(wrappedValue: value)
    }
    
    func decode<T: Decodable>(
        _: Indirect<Optional<T>>.Type,
        forKey key: Key
    ) throws -> Indirect<Optional<T>> {
        let value = try decodeIfPresent(T.self, forKey: key)
        return Indirect(wrappedValue: value)
    }
}
