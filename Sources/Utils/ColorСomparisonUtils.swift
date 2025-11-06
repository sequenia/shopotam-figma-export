//
//  ColorСomparisonUtils.swift
//  shopotam-figma-export
//
//  Created by Ivan Mikhailovskii on 05.11.2025.
//

import Foundation

public class ColorСomparisonUtils {

    public static let instance = ColorСomparisonUtils()
    public var colorsJSON = [String: Any]()

    public func getColorValue(for pathRoles: String) -> String {
        let roleLight = getRoleValue(for: pathRoles)
        if let roleLight = roleLight {
            return getPaletteValue(for: roleLight)
        }

        return getPaletteValue(for: pathRoles)
    }

    private func getRoleValue(for tokenData: String) -> String? {
        var values = colorsJSON["Roles/Light"] as? [String: Any]
        let token = tokenData
        let keys = token
            .dropFirst()
            .dropLast()
            .split(separator: ".").map { String($0) }

        keys.forEach { key in
            values = values?[key] as? [String: Any]
        }

        return values?["value"] as? String
    }

    private func getPaletteValue(for tokenData: String) -> String {
        var values = colorsJSON["Palettes/Value"] as! [String: Any]
        let token = tokenData
        let keys = token
            .dropFirst()
            .dropLast()
            .split(separator: ".").map { String($0) }

        keys.forEach { key in
            values = values[key] as! [String: Any]
        }

        return values["value"] as! String
    }
}
