//
//  Extensions.swift
//  VWConnectAPI
//
//  Created by Christian Menschel on 12.04.21.
//

import Foundation

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

extension JSONEncoder {
    static var shared: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .formatted(DateFormatter.zulu)
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return encoder
    }()
}

func JSONDocumentURL(filename: String, for directory: FileManager.SearchPathDirectory) -> URL? {
    let urls = FileManager.default.urls(for: directory, in: .userDomainMask)
    return urls.first?.appendingPathComponent("\(filename).json")
}

extension NSError {
    static var cannotOpenFile: NSError {
        NSError(domain: NSURLErrorDomain, code: NSURLErrorCannotOpenFile, userInfo: nil)
    }
}

extension FileManager.SearchPathDirectory {
    static var defaultStore: Self {
        .documentDirectory
    }
}

extension Encodable {
    func store(name: String? = nil, at directory: FileManager.SearchPathDirectory = .defaultStore) throws -> Self {
        let name = name ?? String(describing: Self.self)
        guard let url = JSONDocumentURL(filename: name, for: directory) else {
            throw NSError.cannotOpenFile
        }
        let data = try JSONEncoder.shared.encode(self)
        try data.write(to: url, options: .atomicWrite)
        return self
    }
}

extension Decodable {
    static func load(name: String? = nil, at directory: FileManager.SearchPathDirectory = .defaultStore) throws -> Self {
        var decoded: Self?
        let name = name ?? String(describing: Self.self)
        var jsonDecoderError: Error?
        do {
            guard let url = JSONDocumentURL(filename: name, for: directory) else {
                throw NSError.cannotOpenFile
            }
            let data = try Data(contentsOf: url)
            decoded = try JSONDecoder.shared.decode(Self.self, from: data)
        } catch {
            jsonDecoderError = error
        }
        guard let result = decoded else {
            let error = jsonDecoderError ?? NSError.cannotOpenFile
            throw error
        }
        return result
    }
}

extension FileManager {
    static func remove(name: String? = nil, at directory: FileManager.SearchPathDirectory = .defaultStore) throws {
        let name = name ?? String(describing: Self.self)
        guard let url = JSONDocumentURL(filename: name, for: directory) else {
            throw NSError.cannotOpenFile
        }
        try FileManager.default.removeItem(at: url)
    }
}
