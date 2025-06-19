//
//  File.swift
//  shopotam-figma-export
//
//  Created by Ivan Mikhailovskii on 03.06.2025.
//

import Foundation
import FigmaExportCore

@available(macOS 13.0, *)
public class CSSColorParser {

    struct Theme {
        let name: String
        let startIndex: String.Index
        let endIndex: String.Index
    }

    public var colorsDark = [Color]()
    public var colorsLight = [Color]()

    public init(css: String) {
        parse(css)
    }

    func parse(_ css: String) {
        let resultParse = getTheme(css: css)

        resultParse.forEach({
            let result = css[css.index(after: $0.startIndex)..<$0.endIndex]

            let colors = result.split(separator: ";")

            for color in colors {
                let parts = color.split(separator: ":")

                guard parts.count == 2 else { continue }

                let key = String(parts[0].trimmingCharacters(in: .whitespaces))
                let value = String(parts[1].trimmingCharacters(in: .whitespaces))

                let part = value.components(separatedBy: .whitespaces)
                let r = Double(part[0]) ?? 0
                let g = Double(part[1]) ?? 0
                let b = Double(part[2]) ?? 0

                let keyCamelCaseName = toCamelCase(key)

                if $0.name == "light" {
                    colorsLight.append(
                        Color(
                            name: keyCamelCaseName,
                            red: r,
                            green: g,
                            blue: b,
                            alpha: 1
                        )
                    )
                } else {
                    colorsDark.append(
                        Color(
                            name: keyCamelCaseName,
                            red: r,
                            green: g,
                            blue: b,
                            alpha: 1
                        )
                    )
                }
            }
        })
    }

    private func getTheme(css: String) -> [Theme] {
        let startValues = css.ranges(of: #/\.[^\{]+\{/#)
        let endValues = css.ranges(of: #/\}/#)

        if startValues.count != endValues.count {
            fatalError("invalide format css")
        }

        var thems = [Theme]()

        for (index, startValue) in startValues.enumerated() {
            var name = String(css[css.index(after: startValue.lowerBound)..<startValue.upperBound])
                .trimmingCharacters(in: .whitespaces)
            name.removeLast()

            thems.append(
                Theme(
                    name: name.trimmingCharacters(in: .whitespaces),
                    startIndex: startValue.upperBound,
                    endIndex: endValues[index].lowerBound
                )
            )
        }

        return thems
    }

    func toCamelCase(_ string: String) -> String {
        let trimmedStringWithNewLines = string.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedString = trimmedStringWithNewLines.trimmingCharacters(in: ["-"])
        let parts = trimmedString.components(separatedBy: "-")

        guard !parts.isEmpty else { return "" }
        var result = parts.compactMap {
            $0 == "" ? nil : $0.lowercased()
        }.first ?? ""

        for part in parts.dropFirst() {
            guard !part.isEmpty else { continue }

            if part == part.uppercased() {
                result += part.lowercased().capitalized
            } else {
                let firstChar = part.prefix(1).uppercased()
                let remainingChars = part.dropFirst().lowercased()
                result += firstChar + remainingChars
            }
        }

        return result
    }
}
