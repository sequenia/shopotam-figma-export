import ArgumentParser
import Foundation
import FigmaAPI
import XcodeExport
import AndroidExport
import FigmaExportCore
import Logging
import Utils

extension FigmaExportCommand {

    struct ExportColorTokens: ParsableCommand {

        static let configuration = CommandConfiguration(
            commandName: "colorTokens",
            abstract: "Exports ColorTokens",
            discussion: "Exports light and dark color palette from Figma to Xcode / Android Studio project"
        )

        @Option(name: .shortAndLong, help: "An input YAML file with figma and platform properties.")
        var input: String

        @Option(name: .shortAndLong, help: "Target progect name")
        var project: String

        func run() throws {
            let logger = Logger(label: "\(project)")
            let reader = ParamsReader(inputPath: input.isEmpty ? "figma-export.yaml" : input)
            let params = try reader.read()

            guard let colorsSystemURL = params.figma.projects?.first(where: { $0.name == project })?.colorURL
            else { fatalError("No colors system URL found for \(project)") }

            guard let content = try? Data(contentsOf: URL(string: colorsSystemURL)!),
                  let json = try? JSONSerialization.jsonObject(with: content, options: .mutableContainers) as? [String: Any]
            else { return }

            ColorСomparisonUtils.instance.colorsJSON = json

            do {
                let designTokens = try JSONDecoder().decode(ColorTokens.self, from: content)
                var colors = designTokens.stateActive.convertToColors()
                colors.append(contentsOf: designTokens.stateFocus.convertToColors())
                colors.append(contentsOf: designTokens.stateRest.convertToColors())
                colors.append(contentsOf: designTokens.rolesLight.convertToColors())

                if let ios = params.ios {
                    let processor = ColorsProcessor(
                        platform: .ios,
                        nameValidateRegexp: params.common?.colors?.nameValidateRegexp,
                        nameReplaceRegexp: params.common?.colors?.nameReplaceRegexp,
                        ignoreBadNames: false,
                        nameStyle: params.ios?.colors.nameStyle
                    )

                    let colorPairs = try processor.process(
                        light: colors,
                        dark: nil
                    ).get()
                    
                    logger.info("Exporting colors to Xcode project...")
                    try exportXcodeColors(colorPairs: colorPairs, iosParams: ios, logger: logger)
                    logger.info("Done!")
                }

            } catch {
                print("Error decoding JSON: \(error)")
            }
        }

        private func exportXcodeColors(colorPairs: [AssetPair<Color>], iosParams: Params.iOS, logger: Logger) throws {
            var colorsURL: URL?
            if iosParams.colors.useColorAssets {
                if let folder = iosParams.colors.assetsFolder {
                    colorsURL = iosParams.xcassetsPathColors.appendingPathComponent(folder)
                } else {
                    throw FigmaExportError.colorsAssetsFolderNotSpecified
                }
            }

            let output = XcodeColorsOutput(
                assetsColorsURL: colorsURL,
                assetsInMainBundle: iosParams.xcassetsInMainBundle,
                colorSwiftURL: iosParams.colors.colorSwift,
                swiftuiColorSwiftURL: iosParams.colors.swiftuiColorSwift)

            let exporter = XcodeColorExporter(output: output)
            let files = exporter.export(colorPairs: colorPairs)

            if iosParams.colors.useColorAssets, let url = colorsURL {
                try? FileManager.default.removeItem(atPath: url.path)
            }

            try fileWritter.write(files: files)

            do {
                let xcodeProject = try XcodeProjectWritter(
                    xcodeProjPath: iosParams.xcodeprojPath,
                    xcodeprojMainGroupName: iosParams.xcodeprojMainGroupName,
                    target: iosParams.target
                )
                try files.forEach { file in
                    if file.destination.file.pathExtension == "swift" {
                        try xcodeProject.addFileReferenceToXcodeProj(file.destination.url)
                    }
                }
                try xcodeProject.save()
            } catch {
                logger.error("Unable to add some file references to Xcode project")
            }
        }
    }
}

extension StateActive {
    func convertToColors() -> [Color] {
        var colors: [Color] = []
        extractColors(from: self, prefix: "stateActive", to: &colors)
        return colors
    }

    private func extractColors(from object: Any, prefix: String, to colors: inout [Color]) {
        let mirror = Mirror(reflecting: object)

        for child in mirror.children {
            guard let propertyName = child.label else { continue }

            let newPrefix = "\(prefix)\(propertyName.prefix(1).uppercased() + propertyName.dropFirst())"

            switch child.value {
            case let tokenData as TokenData:
                if let color = createColor(from: tokenData, name: newPrefix) {
                    colors.append(color)
                }
            case let optionalTokenData as TokenData?:
                if let tokenData = optionalTokenData, let color = createColor(from: tokenData, name: newPrefix) {
                    colors.append(color)
                }
            default:
                // Рекурсивно обрабатываем вложенные структуры
                extractColors(from: child.value, prefix: newPrefix, to: &colors)
            }
        }
    }

    private func createColor(from tokenData: TokenData, name: String) -> Color? {
        guard case .string(let hexString) = tokenData.value else { return nil }

        let cleanedHex = hexString.replacingOccurrences(of: "#", with: "")
        var rgbValue: UInt64 = 0

        guard Scanner(string: cleanedHex).scanHexInt64(&rgbValue) else { return nil }

        let r, g, b, a: Double
        switch cleanedHex.count {
        case 6:
            r = Double((rgbValue & 0xFF0000) >> 16) / 255.0
            g = Double((rgbValue & 0x00FF00) >> 8) / 255.0
            b = Double(rgbValue & 0x0000FF) / 255.0
            a = 1.0
        case 8:
            r = Double((rgbValue & 0xFF000000) >> 24) / 255.0
            g = Double((rgbValue & 0x00FF0000) >> 16) / 255.0
            b = Double((rgbValue & 0x0000FF00) >> 8) / 255.0
            a = Double(rgbValue & 0x000000FF) / 255.0
        case 3:
            r = Double((rgbValue & 0xF00) >> 8) / 15.0
            g = Double((rgbValue & 0x0F0) >> 4) / 15.0
            b = Double(rgbValue & 0x00F) / 15.0
            a = 1.0
        default:
            return nil
        }

        return Color(name: name, platform: .ios, red: r, green: g, blue: b, alpha: a)
    }
}

extension StateFocus {
    func convertToColors() -> [Color] {
        var colors: [Color] = []
        extractColors(from: self, prefix: "stateFocus", to: &colors)
        return colors
    }

    private func extractColors(from object: Any, prefix: String, to colors: inout [Color]) {
        let mirror = Mirror(reflecting: object)

        for child in mirror.children {
            guard let propertyName = child.label else { continue }

            let newPrefix = "\(prefix)\(propertyName.prefix(1).uppercased() + propertyName.dropFirst())"

            switch child.value {
            case let tokenData as TokenData:
                if let color = createColor(from: tokenData, name: newPrefix) {
                    colors.append(color)
                }
            case let optionalTokenData as TokenData?:
                if let tokenData = optionalTokenData, let color = createColor(from: tokenData, name: newPrefix) {
                    colors.append(color)
                }
            default:
                // Рекурсивно обрабатываем вложенные структуры
                extractColors(from: child.value, prefix: newPrefix, to: &colors)
            }
        }
    }

    private func createColor(from tokenData: TokenData, name: String) -> Color? {
        guard case .string(let hexString) = tokenData.value else { return nil }

        let cleanedHex = hexString.replacingOccurrences(of: "#", with: "")
        var rgbValue: UInt64 = 0

        guard Scanner(string: cleanedHex).scanHexInt64(&rgbValue) else { return nil }

        let r, g, b, a: Double
        switch cleanedHex.count {
        case 6:
            r = Double((rgbValue & 0xFF0000) >> 16) / 255.0
            g = Double((rgbValue & 0x00FF00) >> 8) / 255.0
            b = Double(rgbValue & 0x0000FF) / 255.0
            a = 1.0
        case 8:
            r = Double((rgbValue & 0xFF000000) >> 24) / 255.0
            g = Double((rgbValue & 0x00FF0000) >> 16) / 255.0
            b = Double((rgbValue & 0x0000FF00) >> 8) / 255.0
            a = Double(rgbValue & 0x000000FF) / 255.0
        case 3:
            r = Double((rgbValue & 0xF00) >> 8) / 15.0
            g = Double((rgbValue & 0x0F0) >> 4) / 15.0
            b = Double(rgbValue & 0x00F) / 15.0
            a = 1.0
        default:
            return nil
        }

        return Color(name: name, platform: .ios, red: r, green: g, blue: b, alpha: a)
    }
}

extension StateRest {
    func convertToColors() -> [Color] {
        var colors: [Color] = []
        extractColors(from: self, prefix: "stateRest", to: &colors)
        return colors
    }

    private func extractColors(from object: Any, prefix: String, to colors: inout [Color]) {
        let mirror = Mirror(reflecting: object)

        for child in mirror.children {
            guard let propertyName = child.label else { continue }

            let newPrefix = "\(prefix)\(propertyName.prefix(1).uppercased() + propertyName.dropFirst())"

            switch child.value {
            case let tokenData as TokenData:
                if let color = createColor(from: tokenData, name: newPrefix) {
                    colors.append(color)
                }
            case let optionalTokenData as TokenData?:
                if let tokenData = optionalTokenData, let color = createColor(from: tokenData, name: newPrefix) {
                    colors.append(color)
                }
            default:
                // Рекурсивно обрабатываем вложенные структуры
                extractColors(from: child.value, prefix: newPrefix, to: &colors)
            }
        }
    }

    private func createColor(from tokenData: TokenData, name: String) -> Color? {
        guard case .string(let hexString) = tokenData.value else { return nil }

        let cleanedHex = hexString.replacingOccurrences(of: "#", with: "")
        var rgbValue: UInt64 = 0

        guard Scanner(string: cleanedHex).scanHexInt64(&rgbValue) else { return nil }

        let r, g, b, a: Double
        switch cleanedHex.count {
        case 6:
            r = Double((rgbValue & 0xFF0000) >> 16) / 255.0
            g = Double((rgbValue & 0x00FF00) >> 8) / 255.0
            b = Double(rgbValue & 0x0000FF) / 255.0
            a = 1.0
        case 8:
            r = Double((rgbValue & 0xFF000000) >> 24) / 255.0
            g = Double((rgbValue & 0x00FF0000) >> 16) / 255.0
            b = Double((rgbValue & 0x0000FF00) >> 8) / 255.0
            a = Double(rgbValue & 0x000000FF) / 255.0
        case 3:
            r = Double((rgbValue & 0xF00) >> 8) / 15.0
            g = Double((rgbValue & 0x0F0) >> 4) / 15.0
            b = Double(rgbValue & 0x00F) / 15.0
            a = 1.0
        default:
            return nil
        }

        return Color(name: name, platform: .ios, red: r, green: g, blue: b, alpha: a)
    }
}

extension RolesLight {
    func convertToColors() -> [Color] {
        var colors: [Color] = []
        extractColors(from: self, prefix: "", to: &colors)
        return colors
    }

    private func extractColors(from object: Any, prefix: String, to colors: inout [Color]) {
        let mirror = Mirror(reflecting: object)

        for child in mirror.children {
            guard let propertyName = child.label else { continue }

            let propertyNameComponent = prefix == ""
                ? propertyName.prefix(1).lowercased()
                : propertyName.prefix(1).uppercased()

            let newPrefix = "\(prefix)\(propertyNameComponent + propertyName.dropFirst())"

            switch child.value {
            case let tokenData as TokenData:
                if let color = createColor(from: tokenData, name: newPrefix) {
                    colors.append(color)
                }
            case let optionalTokenData as TokenData?:
                if let tokenData = optionalTokenData, let color = createColor(from: tokenData, name: newPrefix) {
                    colors.append(color)
                }
            default:
                // Рекурсивно обрабатываем вложенные структуры
                extractColors(from: child.value, prefix: newPrefix, to: &colors)
            }
        }
    }

    private func createColor(from tokenData: TokenData, name: String) -> Color? {
        guard case .string(let hexString) = tokenData.value else { return nil }

        let cleanedHex = hexString.replacingOccurrences(of: "#", with: "")
        var rgbValue: UInt64 = 0

        guard Scanner(string: cleanedHex).scanHexInt64(&rgbValue) else { return nil }

        let r, g, b, a: Double
        switch cleanedHex.count {
        case 6:
            r = Double((rgbValue & 0xFF0000) >> 16) / 255.0
            g = Double((rgbValue & 0x00FF00) >> 8) / 255.0
            b = Double(rgbValue & 0x0000FF) / 255.0
            a = 1.0
        case 8:
            r = Double((rgbValue & 0xFF000000) >> 24) / 255.0
            g = Double((rgbValue & 0x00FF0000) >> 16) / 255.0
            b = Double((rgbValue & 0x0000FF00) >> 8) / 255.0
            a = Double(rgbValue & 0x000000FF) / 255.0
        case 3:
            r = Double((rgbValue & 0xF00) >> 8) / 15.0
            g = Double((rgbValue & 0x0F0) >> 4) / 15.0
            b = Double(rgbValue & 0x00F) / 15.0
            a = 1.0
        default:
            return nil
        }

        return Color(name: name, platform: .ios, red: r, green: g, blue: b, alpha: a)
    }
}
