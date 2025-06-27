//
//  File.swift
//  shopotam-figma-export
//
//  Created by Ivan Mikhailovskii on 19.06.2025.
//

public struct SVGImage {
    public let name: String
    public let contentSvg: String

    public init(name: String, contentSvg: String) {
        self.name = name
        self.contentSvg = contentSvg
    }
}
